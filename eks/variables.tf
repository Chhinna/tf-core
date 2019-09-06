variable "region" {
  description = "Region"
}

variable "created_by" {
  description = "Created By"
}

variable "cluster" {
  description = "Cluster"
}

variable "environment" {
  description = "Environment"
}

variable "team" {
  description = "Team"
}

variable "create_controlplane_security_group" {
  description = "Flag to create controlplane security group"
  default     = true
}

variable "enabled_cluster_log_types" {
  description = "A list of the desired control plane logging to enable. Valid values are: api, audit, authenticator, controllerManager, scheduler"
  type        = "list"
  default     = ["api", "audit"]
}

variable "log_retention_in_days" {
  description = "If cluster logging enabled, Cloudwatch log retention in days"
  default     = 7
}

variable "extra_tags" {
  description = "Extra tags"
  type        = "map"
  default     = {}
}

variable "manage_iam_resources" {
  description = "Flag to manage iam resources"
  default     = true
}

variable "iam_role_arn" {
  description = "If iam resources are not managed automatically, pass iam role arn which will be attached to cluster"
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs where cluster will be created and managed by AWS"
  type        = "list"
}

variable "enable_endpoint_private_access" {
  description = "Flag to enable private endpoint for EKS Master"
}

variable "enable_endpoint_public_access" {
  description = "Flag to enable public endpoint for EKS Master"
}

variable "security_group_ids" {
  description = "Security groups which will be attached to EKS Master/controlplane"
  type        = "list"
  default     = []
}

variable "create_timeout" {
  description = "Create timeout"
  default     = "30m"
}

variable "delete_timeout" {
  description = "Delete timeout"
  default     = "15m"
}

variable "update_timeout" {
  description = "Update timeout"
  default     = "30m"
}

variable "vpc_id" {
  description = "VPC ID"
}
