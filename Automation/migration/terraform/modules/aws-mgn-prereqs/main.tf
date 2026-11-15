terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_security_group" "mgn_staging" {
  count = var.create_staging_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-mgn-staging-"
  description = "MGN staging area security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mgn-staging"
  })
}
