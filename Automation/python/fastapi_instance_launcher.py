#!/usr/bin/env python3
"""
FastAPI service to launch hardened Windows or RHEL EC2 instances
for CI/CD agents or lightweight ML workloads.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import boto3
from typing import Literal

app = FastAPI(title="CI/ML Instance Launcher", version="0.1.0")
ec2 = boto3.client("ec2")

class LaunchRequest(BaseModel):
    os: Literal["windows", "rhel"]
    instance_type: str = "m6i.xlarge"
    subnet_id: str
    security_group_ids: list[str]
    key_name: str | None = None
    volume_size: int = Field(default=80, ge=30, le=500)

def get_latest_ami(os: str) -> str:
    filters = [
        {"Name": "tag:Role", "Values": ["CI-CD-ML"]},
        {"Name": "tag:OS", "Values": [os.upper()]},
        {"Name": "state", "Values": ["available"]},
    ]
    resp = ec2.describe_images(Owners=["self"], Filters=filters)
    images = sorted(resp["Images"], key=lambda x: x["CreationDate"], reverse=True)
    if not images:
        raise HTTPException(404, f"No AMI found for OS={os}")
    return images[0]["ImageId"]

@app.post("/launch")
def launch_instance(req: LaunchRequest):
    ami_id = get_latest_ami(req.os)

    kwargs = {
        "ImageId": ami_id,
        "InstanceType": req.instance_type,
        "MinCount": 1,
        "MaxCount": 1,
        "SubnetId": req.subnet_id,
        "SecurityGroupIds": req.security_group_ids,
        "BlockDeviceMappings": [{
            "DeviceName": "/dev/sda1",
            "Ebs": {
                "VolumeSize": req.volume_size,
                "VolumeType": "gp3",
                "Encrypted": True,
                "DeleteOnTermination": True,
            }
        }],
        "MetadataOptions": {
            "HttpTokens": "required",
            "HttpPutResponseHopLimit": 2,
        },
        "TagSpecifications": [{
            "ResourceType": "instance",
            "Tags": [
                {"Key": "Name", "Value": f"{req.os}-ci-ml-api"},
                {"Key": "Role", "Value": "CI-CD-ML"},
                {"Key": "OS", "Value": req.os.upper()},
            ]
        }],
        "Monitoring": {"Enabled": True},
    }
    if req.key_name:
        kwargs["KeyName"] = req.key_name

    resp = ec2.run_instances(**kwargs)
    instance_id = resp["Instances"][0]["InstanceId"]
    return {"instance_id": instance_id, "ami_id": ami_id, "os": req.os}

@app.get("/health")
def health():
    return {"status": "ok"}
