output "launch_template_name" {
  value = aws_launch_template.eks_lt.name_prefix
}
output "eks_lt_name" {
  description = "Cluster Role ARN"
  value       = aws_launch_template.eks_lt.name
}
output "eks_lt_latest_version" {
  description = "Cluster Role ARN"
  value       = aws_launch_template.eks_lt.latest_version
}