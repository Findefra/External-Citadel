# AWS MGN prerequisites (thin module)

Minimal Terraform module for **AWS Application Migration Service (MGN)** staging prerequisites:

- Staging subnet outputs for replication templates
- Optional dedicated staging security group

Not a full migration factory. Agent install, waves, and cutover remain operational.

## Usage

```hcl
module "mgn_prereqs" {
  source = "./modules/aws-mgn-prereqs"

  name_prefix        = "migr"
  vpc_id             = "vpc-abc"
  staging_subnet_ids = ["subnet-aaa", "subnet-bbb"]
  tags               = { Project = "cloud-migration" }
}
```

## After apply

```bash
../../validate/post-apply-validate.sh --cloud aws --region us-east-1
```
