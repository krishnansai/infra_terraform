output "aws_iam_openid_connect_provider_arn" {
  description = "Cluster Role ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "aws_iam_openid_connect_provider_url" {
  description = "Cluster Role ARN"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "cluster_name" {
  description = "Cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "certificate_authority_data" {
  description = "Certificate authority data"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}