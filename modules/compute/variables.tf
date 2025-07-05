variable "name" {
  type        = string
  description = "A name for this stack"
}

variable "eks_version" {
  type    = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "log_retention" {
  type    = string
}

variable "key_id" {
  type    = string
}

variable "kube-proxy_addon_version" {
  type    = string
}

variable "coredns_addon_version" {
  type    = string
}

variable "vpc-cni_addon_version" {
  type    = string
}

variable "ebs-csidriver_addon_version" {
  type    = string
}

############################## EKS Worker Nodes Variables ##################################

variable "worker_desired_size" {
  type        = number
  description = "The minimum number of instances that will be launched by this group, if not a multiple of the number of AZs in the group, may be rounded up"
}
variable "worker_max_size" {
  type        = number
  description = "The minimum number of instances that will be launched by this group, if not a multiple of the number of AZs in the group, may be rounded up"
}

variable "worker_min_size" {
  type        = number
  description = "The minimum number of instances that will be launched by this group, if not a multiple of the number of AZs in the group, may be rounded up"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "Cluster role ARN"
  type    = string
}

variable "managed_workers_arn" {
  description = "Managed workers role ARN"
  type    = string
}

variable "aws_security_group_control_plane_id" {
  description = "The Security group id used for cluster creation"
  type        = list(string)
}

variable "eks_lt_name" {
  description = "EKS launchtemplate name"
  type    = string
}

variable "eks_lt_latest_version" {
  description = "EKS launchtemplate latest version"
  type        = number
}

variable "config_map_aws_auth" {
  description = "The content of the config map for AWS auth"
  type        = string
}