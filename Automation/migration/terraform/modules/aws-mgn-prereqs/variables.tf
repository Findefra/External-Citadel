variable "name_prefix" {
  type        = string
  description = "Prefix for named resources"
  default     = "mgn"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used for MGN staging networking"
}

variable "staging_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for MGN staging area / replication resources"
}

variable "create_staging_security_group" {
  type        = bool
  description = "Whether to create a dedicated staging security group"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to created resources"
  default     = {}
}
