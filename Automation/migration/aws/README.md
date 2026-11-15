# AWS Post-Migration Health Checks

Uses **AWS CLI** against native inventory and health signals after MGN / lift-and-shift / rehost style migrations.

## Script

`post-migration-health-check.sh`

Checks (configurable via flags):

- EC2 instance states (running vs stopped/impaired)
- ELB/ALB target health (optional target group ARNs)
- RDS instance status (optional)
- CloudWatch alarms in ALARM state (optional region-wide sample)

## Usage

```bash
export AWS_PROFILE=migration
./post-migration-health-check.sh --region us-east-1 --report-dir ../reports

./post-migration-health-check.sh \
  --region us-west-2 \
  --target-group-arns arn:aws:elasticloadbalancing:...:targetgroup/app/abc \
  --rds-instance-ids mydb \
  --report-dir ../reports
```

Requires: `aws` CLI, `jq` recommended (script falls back if missing for some fields).
