variable "name" {
  type        = string
  description = "A name for this stack"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
}

# variable "security_group_id" {
#   description = "Security Group ID"
# }

variable "az_counts" {
  description = "Availability zone counts"
}
variable "private_az_counts" {
  description = "Availability zone counts for private"
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}
variable "private_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}