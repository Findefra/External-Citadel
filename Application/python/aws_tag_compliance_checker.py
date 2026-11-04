#!/usr/bin/env python3
"""
AWS Tag Compliance Checker – EC2, RDS, S3
"""

import boto3
import click
import csv
from pathlib import Path

REQUIRED_TAGS = {"Environment", "Owner", "CostCenter", "Application"}

ec2 = boto3.client("ec2")
rds = boto3.client("rds")
s3 = boto3.client("s3")

def check_tags(tags: list[dict] | None) -> list[str]:
    if not tags:
        return list(REQUIRED_TAGS)
    present = {t["Key"] for t in tags}
    return list(REQUIRED_TAGS - present)

@click.command()
@click.option("--output", default="tag-compliance.csv", help="Output CSV file")
def main(output: str):
    results = []

    for reservation in ec2.describe_instances()["Reservations"]:
        for inst in reservation["Instances"]:
            missing = check_tags(inst.get("Tags"))
            if missing:
                results.append({
                    "Service": "EC2",
                    "ResourceId": inst["InstanceId"],
                    "MissingTags": ";".join(missing),
                    "Region": boto3.Session().region_name
                })

    for db in rds.describe_db_instances()["DBInstances"]:
        results.append({
            "Service": "RDS",
            "ResourceId": db["DBInstanceIdentifier"],
            "MissingTags": "Check manually / extend code",
            "Region": boto3.Session().region_name
        })

    for bucket in s3.list_buckets()["Buckets"]:
        name = bucket["Name"]
        try:
            tagset = s3.get_bucket_tagging(Bucket=name).get("TagSet", [])
            missing = check_tags(tagset)
            if missing:
                results.append({
                    "Service": "S3",
                    "ResourceId": name,
                    "MissingTags": ";".join(missing),
                    "Region": "global"
                })
        except s3.exceptions.ClientError:
            results.append({
                "Service": "S3",
                "ResourceId": name,
                "MissingTags": "NoTagging or AccessDenied",
                "Region": "global"
            })

    path = Path(output)
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["Service", "ResourceId", "MissingTags", "Region"])
        writer.writeheader()
        writer.writerows(results)

    click.echo(f"Wrote {len(results)} findings to {path}")

if __name__ == "__main__":
    main()
