############### VPC variables ###############
variable "name" {
  type        = string
  description = "A name for this stack"
}

variable "region" {
  type        = string
  description = "Region where this stack will be deployed"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
}


# variable "security_group_id" {
#   default     = "sg-05b64ff0b679a567a"
# }


variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}
variable "private_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}

variable "availability_zones" {
  description = "The availability zones to create subnets in"
}

variable "az_counts" {
}

variable "private_az_counts" {
}

############################ Launch template variables ##################
variable "eks_ami_id" {
  description = "Use UBUNTU LATEST EKS OS AMI Imaged ID"
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

variable "instance_size" {
  type        = string
  description = "The size of instances in this node group"
  default     = "m5a.xlarge"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "root_volume_size" {
  type        = number
  description = "Volume size for the root partition"
}


############################## EKS Variables ##################################
variable "key_id" {
  type    = string
}
variable "legacy_security_groups" {
  type        = bool
  default     = false
  description = "Preserves existing security group setup from pre 1.15 clusters, to allow existing clusters to be upgraded without recreation"
}

variable "log_retention" {
  type    = string
  default = "90"
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

variable "aws_auth_role_map" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default     = []
  description = "A list of mappings from aws role arns to kubernetes users, and their groups"
}


variable "aws_auth_user_map" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default     = []
  description = "A list of mappings from aws user arns to kubernetes users, and their groups"
}

variable "fstype" {
  type        = string
  default     = "xfs"
  description = "File system type that will be formatted during volume creation, (xfs, ext2, ext3 or ext4)"
}

variable "eks_version" {
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

############################## EKS IAM Variables ##################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler" {
  type        = bool
  default     = true
  description = "Should this group be managed by the cluster autoscaler"
}

variable "aws_account_id" {
    description = "AWS platform account id"
}

variable "eks_cluster_name" {
    description = "AWS EKS Cluster Name"
    default = "eks-staging"
}

variable "env" {
    description = "AWS EKS Cluster Environment"
}

############################## RDS Variables ##################################

variable "rds_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}

variable "rds_engine" {
  description = "The database engine to use"
  type        = string
}

variable "rds_engine_version" {
  description = "The engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "rds_db_name" {
  description = "The name of the database"
  type        = string
}

variable "rds_username" {
  description = "The master username for the database"
  type        = string
}

variable "rds_password" {
  description = "The master password for the database"
  type        = string
}

variable "rds_parameter_group_name" {
  description = "The parameter group to associate with the DB instance"
  type        = string
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot of the database before deletion"
  type        = bool
  default     = true
}

variable "rds_publicly_accessible" {
  description = "Whether the DB instance is publicly accessible"
  type        = bool
  default     = false
}