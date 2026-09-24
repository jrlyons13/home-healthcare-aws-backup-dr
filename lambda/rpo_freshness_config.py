"""AWS Config custom rule: S3 backup recovery point freshness (RPO) for a vault."""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _parse_rule_parameters(event: dict) -> dict:
    raw = event.get("ruleParameters") or "{}"
    if isinstance(raw, str):
        return json.loads(raw) if raw else {}
    return raw


def _latest_completed_s3_recovery(
    backup_client,
    *,
    vault_name: str,
    bucket_arn: str,
) -> datetime | None:
    bucket_name = bucket_arn.split(":::")[-1]
    latest: datetime | None = None

    paginator = backup_client.get_paginator("list_recovery_points_by_backup_vault")
    for page in paginator.paginate(BackupVaultName=vault_name):
        for rp in page.get("RecoveryPoints", []):
            if rp.get("ResourceType") != "S3":
                continue
            if rp.get("Status") != "COMPLETED":
                continue
            resource_arn = rp.get("ResourceArn") or ""
            if bucket_arn not in resource_arn and bucket_name not in resource_arn:
                continue
            completed = rp.get("CompletionDate")
            if completed is None:
                continue
            if completed.tzinfo is None:
                completed = completed.replace(tzinfo=timezone.utc)
            if latest is None or completed > latest:
                latest = completed
    return latest


def evaluate_compliance(event: dict) -> str:
    params = _parse_rule_parameters(event)
    max_age_hours = float(params.get("max_age_hours", "26"))
    vault_name = params["vault_name"]
    backup_region = params["backup_region"]
    bucket_arn = params["bucket_arn"]
    bucket_name = bucket_arn.split(":::")[-1]

    backup = boto3.client("backup", region_name=backup_region)
    latest = _latest_completed_s3_recovery(
        backup,
        vault_name=vault_name,
        bucket_arn=bucket_arn,
    )

    if latest is None:
        compliance = "NON_COMPLIANT"
        annotation = f"No COMPLETED S3 recovery point in {vault_name} ({backup_region})"
    else:
        now = datetime.now(timezone.utc)
        age_hours = (now - latest).total_seconds() / 3600.0
        if age_hours <= max_age_hours:
            compliance = "COMPLIANT"
            annotation = f"Latest point {age_hours:.1f}h old (max {max_age_hours}h)"
        else:
            compliance = "NON_COMPLIANT"
            annotation = f"Latest point {age_hours:.1f}h old exceeds max {max_age_hours}h"

    logger.info(
        "RPO_FRESHNESS vault=%s region=%s compliance=%s %s",
        vault_name,
        backup_region,
        compliance,
        annotation,
    )

    config = boto3.client("config")
    config.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType": "AWS::S3::Bucket",
                "ComplianceResourceId": bucket_name,
                "ComplianceType": compliance,
                "Annotation": annotation[:256],
                "OrderingTimestamp": datetime.now(timezone.utc),
            }
        ],
        ResultToken=event["resultToken"],
        TestMode=event.get("testMode", False),
    )
    return compliance


def lambda_handler(event, context):
    return evaluate_compliance(event)
