output "private_subnet_id" {
  value          = [for az, subnet in aws_subnet.private: subnet.id]
}
output "public_subnet_id" {
  value          = [for az, subnet in aws_subnet.public: subnet.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public.*.id
}

output "aws_security_group_control_plane_id" {
  value       = aws_security_group.control_plane.id
  description = "The Security group id used for cluster creation"
}

output "aws_security_group_worker_node_id" {
  value       = aws_security_group.worker_node_sg.id
  description = "The Security group id used for cluster creation"
}
output "aws_nat_gateway_id" {
  description = "Nat Gateway ID"
  value       = aws_nat_gateway.eks_network_nat_gateway.id
}