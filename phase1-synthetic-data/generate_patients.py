#!/usr/bin/env python3
"""Generate synthetic home healthcare ePHI records for backup/DR lab use."""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

GENERATOR_VERSION = "1.0.0"

FIRST_NAMES = [
    "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Quinn", "Avery",
]
LAST_NAMES = [
    "Synthetic", "Labpatient", "Testerson", "Demohealth", "Mockfield",
]
SERVICE_TYPES = [
    "skilled_nursing",
    "physical_therapy",
    "occupational_therapy",
    "speech_therapy",
    "home_health_aide",
]
ICD10_CODES = ["I10", "E11.9", "J44.9", "M79.3", "N18.3", "F03.90", "I50.9"]
MEDICATIONS = [
    ("Lisinopril", "10 mg daily"),
    ("Metformin", "500 mg twice daily"),
    ("Amlodipine", "5 mg daily"),
    ("Atorvastatin", "20 mg at bedtime"),
    ("Furosemide", "40 mg daily"),
]
CARE_PLAN_TEMPLATES = [
    "Monitor vital signs and medication compliance during home visits.",
    "Assist with mobility exercises and document functional progress.",
    "Provide wound care and infection monitoring per physician orders.",
    "Support ADLs and caregiver education for chronic condition management.",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate synthetic home healthcare patient records (JSON)."
    )
    parser.add_argument(
        "--count",
        type=int,
        default=10,
        help="Number of patient records to generate (default: 10)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("output"),
        help="Output directory (default: ./output)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Random seed for reproducible generation",
    )
    return parser.parse_args()


def iso_date(d: date) -> str:
    return d.isoformat()


def build_record(index: int, rng: random.Random) -> dict:
    patient_num = f"{index:06d}"
    patient_id = f"SYN-{patient_num}"
    visit_date = date.today() - timedelta(days=rng.randint(0, 90))
    dob = date(1940, 1, 1) + timedelta(days=rng.randint(0, 25000))
    med_count = rng.randint(0, 3)
    meds = [
        {"name": name, "dosage": dosage}
        for name, dosage in rng.sample(MEDICATIONS, k=med_count)
    ]

    return {
        "patient_id": patient_id,
        "record_type": "home_health_visit",
        "demographics": {
            "first_name": rng.choice(FIRST_NAMES),
            "last_name": f"{rng.choice(LAST_NAMES)}{index}",
            "date_of_birth": iso_date(dob),
            "mrn": f"MRN-SYN-{patient_num}",
        },
        "visit": {
            "visit_date": iso_date(visit_date),
            "caregiver_npi": f"999{rng.randint(0, 9999999):07d}",
            "service_type": rng.choice(SERVICE_TYPES),
            "visit_duration_minutes": rng.choice([45, 60, 90, 120]),
        },
        "clinical": {
            "primary_diagnosis_icd10": rng.choice(ICD10_CODES),
            "care_plan_summary": rng.choice(CARE_PLAN_TEMPLATES),
            "medications": meds,
        },
        "metadata": {
            "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
            "generator_version": GENERATOR_VERSION,
            "synthetic_data_notice": "SYNTHETIC_EPHI_LAB_DATA_ONLY",
        },
    }


def file_hashes(content: bytes) -> tuple[str, str]:
    return (
        hashlib.md5(content).hexdigest(),
        hashlib.sha256(content).hexdigest(),
    )


def write_record(patients_dir: Path, record: dict) -> dict:
    filename = f"{record['patient_id']}.json"
    path = patients_dir / filename
    payload = json.dumps(record, indent=2, sort_keys=True) + "\n"
    content = payload.encode("utf-8")
    path.write_bytes(content)
    md5, sha256 = file_hashes(content)
    return {
        "key": f"patients/{filename}",
        "patient_id": record["patient_id"],
        "bytes": len(content),
        "md5": md5,
        "sha256": sha256,
    }


def main() -> int:
    args = parse_args()
    if args.count < 1:
        print("Error: --count must be at least 1", file=sys.stderr)
        return 1

    rng = random.Random(args.seed)
    output_dir = args.output.resolve()
    patients_dir = output_dir / "patients"
    patients_dir.mkdir(parents=True, exist_ok=True)

    objects = []
    for i in range(1, args.count + 1):
        record = build_record(i, rng)
        objects.append(write_record(patients_dir, record))

    manifest = {
        "manifest_version": "1.0",
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "generator_version": GENERATOR_VERSION,
        "record_count": len(objects),
        "objects": objects,
    }
    manifest_path = output_dir / "manifest.json"
    manifest_text = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    manifest_path.write_text(manifest_text, encoding="utf-8")
    _, sha256 = file_hashes(manifest_text.encode("utf-8"))

    print(f"Generated {len(objects)} records in {output_dir}")
    print(f"Manifest: {manifest_path}")
    print(f"Manifest SHA-256: {sha256}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
