#!/bin/bash
# 03-create-ami.sh
# Create an AMI from a running EC2 instance
set -euo pipefail

INSTANCE_ID="${1:?Usage: $0 i-xxxxxxxxxxxxxxxxx}"
NAME="backup-$(hostname)-$(date +%Y%m%d-%H%M)"
REGION="${AWS_REGION:-us-west-2}"

AMI_ID=$(aws ec2 create-image \
  --instance-id "$INSTANCE_ID" \
  --name "$NAME" \
  --description "Automated AMI created $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --no-reboot \
  --region "$REGION" \
  --query ImageId --output text)

aws ec2 create-tags \
  --resources "$AMI_ID" \
  --region "$REGION" \
  --tags Key=Name,Value="$NAME" \
         Key=SourceInstance,Value="$INSTANCE_ID" \
         Key=AutoBackup,Value=true

echo "AMI $AMI_ID created (no-reboot)."
echo "Monitor: aws ec2 describe-images --image-ids $AMI_ID --region $REGION"
