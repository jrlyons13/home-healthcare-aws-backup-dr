"""AWS Lambda: verify restored S3 objects against baseline manifest (hashes + basic checks)."""

from __future__ import annotations

import hashlib
import json
import logging
import os
import re
from typing import Any

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

PATIENT_ID_PATTERN = re.compile(r"^SYN-[0-9]{6}$")


def _env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def file_hashes(content: bytes) -> tuple[str, str]:
    return hashlib.md5(content).hexdigest(), hashlib.sha256(content).hexdigest()


def load_manifest(bucket: str, manifest_key: str) -> dict[str, Any]:
    response = s3.get_object(Bucket=bucket, Key=manifest_key)
    return json.loads(response["Body"].read().decode("utf-8"))


def object_key(prefix: str, manifest_object_key: str) -> str:
    cleaned = prefix.strip("/")
    return f"{cleaned}/{manifest_object_key}" if cleaned else manifest_object_key


def basic_record_checks(record: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    patient_id = record.get("patient_id", "")
    if not PATIENT_ID_PATTERN.match(patient_id):
        errors.append(f"Invalid patient_id: {patient_id}")
    if record.get("record_type") != "home_health_visit":
        errors.append("record_type must be home_health_visit")
    notice = record.get("metadata", {}).get("synthetic_data_notice")
    if notice != "SYNTHETIC_EPHI_LAB_DATA_ONLY":
        errors.append("missing synthetic_data_notice")
    return errors


def verify_restored_objects(
    bucket: str,
    verify_prefix: str,
    manifest_key: str,
) -> tuple[bool, list[str]]:
    errors: list[str] = []
    manifest = load_manifest(bucket, manifest_key)
    objects = manifest.get("objects", [])

    if not objects:
        return False, ["Manifest contains no objects to verify"]

    for obj in objects:
        rel_key = obj["key"]
        key = object_key(verify_prefix, rel_key)
        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            content = response["Body"].read()
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code", "")
            if code in {"NoSuchKey", "404"}:
                errors.append(f"Missing restored object: {key}")
            else:
                errors.append(f"Failed to read {key}: {exc}")
            continue

        md5, sha256 = file_hashes(content)
        if md5 != obj.get("md5") or sha256 != obj.get("sha256"):
            errors.append(f"Hash mismatch for {key}")
            continue

        try:
            record = json.loads(content.decode("utf-8"))
        except json.JSONDecodeError:
            errors.append(f"Invalid JSON: {key}")
            continue

        errors.extend(f"{key}: {msg}" for msg in basic_record_checks(record))

    return len(errors) == 0, errors


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    detail = event.get("detail", {})
    state = detail.get("state") or detail.get("status")
    resource_type = detail.get("resourceType")

    logger.info("Event received: state=%s resourceType=%s", state, resource_type)

    if state and state != "COMPLETED":
        logger.info("Skipping verification; restore job state is %s", state)
        return {"skipped": True, "state": state}

    bucket = _env("BUCKET_NAME")
    verify_prefix = os.environ.get("VERIFY_PREFIX") or os.environ.get("SANDBOX_PREFIX") or ""
    manifest_key = os.environ.get("MANIFEST_KEY", "manifest.json")

    passed, errors = verify_restored_objects(bucket, verify_prefix, manifest_key)

    if passed:
        logger.info("VERIFICATION_RESULT=PASS records=%s", len(load_manifest(bucket, manifest_key).get("objects", [])))
        return {"result": "PASS"}

    for err in errors:
        logger.error("Verification error: %s", err)
    logger.error("VERIFICATION_RESULT=FAIL error_count=%s", len(errors))
    return {"result": "FAIL", "errors": errors}
