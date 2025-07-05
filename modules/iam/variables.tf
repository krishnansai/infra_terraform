variable "name" {
  type        = string
  description = "A name for this stack"
}

variable "env" {
    description = "AWS EKS Cluster Environment"
}

variable "aws_iam_openid_connect_provider_arn" {
  description = "ARN"
}

variable "aws_iam_openid_connect_provider_url" {
  description = "URL"
}

variable "aws_account_id" {
    description = "AWS platform account id"
}

variable "region" {
    description = "AWS platform account id"
}

variable "key_id" {
    description = "AWS platform account id"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}