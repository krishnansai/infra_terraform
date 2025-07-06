variable "allocated_storage" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "db_name" {}
variable "username" {}
variable "password" {}
variable "parameter_group_name" {}
variable "db_subnet_group_name" {
  description = "The DB subnet group to use for the DB instance"
  type        = string
  default     = null
}
variable "vpc_security_group_ids" { type = list(string) }
variable "skip_final_snapshot" { default = true }
variable "publicly_accessible" { default = false }
variable "tags" { type = map(string) }
variable "identifier" {
  description = "The name for the RDS instance"
  type        = string
}
