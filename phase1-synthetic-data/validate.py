#!/usr/bin/env python3
"""Validate synthetic patient records against JSON Schema and manifest hashes."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
    from jsonschema.exceptions import ValidationError
except ImportError:
    print("Error: jsonschema is required. Run: pip install -r requirements.txt", file=sys.stderr)
    raise SystemExit(1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate synthetic patient JSON records and manifest integrity."
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("output"),
        help="Directory containing patients/ and manifest.json (default: ./output)",
    )
    parser.add_argument(
        "--schema",
        type=Path,
        default=Path(__file__).parent / "patient_record.schema.json",
        help="Path to JSON Schema file",
    )
    return parser.parse_args()


def file_hashes(content: bytes) -> tuple[str, str]:
    return (
        hashlib.md5(content).hexdigest(),
        hashlib.sha256(content).hexdigest(),
    )


def validate_schema(records_dir: Path, schema: dict) -> tuple[int, int, list[str]]:
    validator = Draft202012Validator(schema)
    passed = 0
    failed = 0
    errors: list[str] = []

    for path in sorted(records_dir.glob("SYN-*.json")):
        record = json.loads(path.read_text(encoding="utf-8"))
        schema_errors = sorted(validator.iter_errors(record), key=lambda e: e.path)
        if schema_errors:
            failed += 1
            for err in schema_errors:
                errors.append(f"{path.name}: {err.message}")
        else:
            passed += 1

    return passed, failed, errors


def validate_manifest(output_dir: Path) -> tuple[int, int, list[str]]:
    manifest_path = output_dir / "manifest.json"
    errors: list[str] = []

    if not manifest_path.is_file():
        return 0, 1, ["manifest.json not found"]

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    objects = manifest.get("objects", [])
    passed = 0
    failed = 0

    for obj in objects:
        rel_key = obj["key"]
        file_path = output_dir / Path(rel_key)
        if not file_path.is_file():
            failed += 1
            errors.append(f"Missing file for manifest entry: {rel_key}")
            continue

        content = file_path.read_bytes()
        md5, sha256 = file_hashes(content)
        if md5 != obj["md5"] or sha256 != obj["sha256"]:
            failed += 1
            errors.append(f"Hash mismatch: {rel_key}")
        else:
            passed += 1

    declared_count = manifest.get("record_count")
    actual_files = len(list((output_dir / "patients").glob("SYN-*.json")))
    if declared_count != len(objects):
        failed += 1
        errors.append(
            f"record_count ({declared_count}) does not match objects length ({len(objects)})"
        )
    if declared_count != actual_files:
        failed += 1
        errors.append(
            f"record_count ({declared_count}) does not match patient files on disk ({actual_files})"
        )

    return passed, failed, errors


def main() -> int:
    args = parse_args()
    output_dir = args.output.resolve()
    patients_dir = output_dir / "patients"

    if not patients_dir.is_dir():
        print(f"Error: patients directory not found: {patients_dir}", file=sys.stderr)
        return 1

    schema = json.loads(args.schema.read_text(encoding="utf-8"))
    schema_pass, schema_fail, schema_errors = validate_schema(patients_dir, schema)
    manifest_pass, manifest_fail, manifest_errors = validate_manifest(output_dir)

    total_records = schema_pass + schema_fail
    print(f"Schema validation: {'PASS' if schema_fail == 0 else 'FAIL'} ({schema_pass}/{total_records} records)")
    print(f"Manifest hash check: {'PASS' if manifest_fail == 0 else 'FAIL'}")

    all_errors = schema_errors + manifest_errors
    for err in all_errors:
        print(f"  - {err}", file=sys.stderr)

    if schema_fail or manifest_fail:
        print("VERIFICATION_RESULT=FAIL")
        return 1

    print("VERIFICATION_RESULT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
