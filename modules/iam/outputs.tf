output "cluster_role_arn" {
  description = "Cluster Role ARN"
  value       = aws_iam_role.cluster_role.arn
}

output "managed_workers_arn" {
  description = "Cluster Role ARN"
  value       = aws_iam_role.managed_workers.arn
}