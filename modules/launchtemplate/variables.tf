variable "cluster_autoscaler" {
  type        = bool
  description = "Should this group be managed by the cluster autoscaler"
}

variable "env" {
    description = "AWS EKS Cluster Environment"
}

variable "name" {
  type        = string
  description = "A name for this stack"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels that will be added to the kubernetes node."
}

variable "taints" {
  type        = map(string)
  default     = { }
  description = "taints that will be added to the kubernetes node"
}

variable "region" {
  type        = string
  description = "Region where this stack will be deployed"
}

variable "instance_size" {
  type        = string
  description = "The size of instances in this node group"
}

variable "root_volume_size" {
  type        = number
  description = "Volume size for the root partition"
}

variable "eks_ami_id" {
  description = "Use UBUNTU LATEST EKS OS AMI Imaged ID"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "aws_security_group_worker_node_id" {
  description = "The Security group id used for cluster creation"
}
variable "managed_workers_arn" {
  description = "Managed workers role ARN"
  type    = string
}

variable "cluster_name" {
  description = "Cluster Name"
  type    = string
}

variable "cluster_endpoint" {
  description = "Cluster endpoint"
  type    = string
}
variable "certificate_authority_data" {
  description = "Certificate authority data"
  type    = string
}