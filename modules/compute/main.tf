####### Fetching the EKS KMS ############
data "aws_kms_key" "eks_kms_key_arn" {
  key_id = var.key_id
}

####### Creating aws auth configmap ############
resource "local_file" "aws_auth_configmap" {
  content         = var.config_map_aws_auth
  filename        = "${path.module}/config_map_aws_auth.yaml"
  file_permission = "0644"
}

resource "aws_eks_cluster" "cluster" {
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  name                      = var.name
  role_arn                  = var.cluster_role_arn
  version                   = var.eks_version
  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = var.aws_security_group_control_plane_id
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }
  tags = var.tags
  depends_on = [
    aws_cloudwatch_log_group.cluster,
  ]
  provisioner "local-exec" {
    command     = "until curl --output /dev/null --insecure --silent ${self.endpoint}/healthz; do sleep 1; done"
    working_dir = path.module
  }
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = data.aws_kms_key.eks_kms_key_arn.arn
    }
  }
}
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/ekslogs/${var.name}/cluster"
  retention_in_days = var.log_retention
}

####### EKS - OIDC ################
data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

### EKS Addons for AWS Kubernetes #####
#### Kube-proxy ######
resource "aws_eks_addon" "kube-proxy" {
  cluster_name                   = aws_eks_cluster.cluster.name
  addon_name                     = "kube-proxy"
  addon_version                  = var.kube-proxy_addon_version
  resolve_conflicts_on_create    = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.worker-node-group_4
  ]
}

#### Core-DNS ######
resource "aws_eks_addon" "coredns" {
  cluster_name                   = aws_eks_cluster.cluster.name
  addon_name                     = "coredns"
  addon_version                  = var.coredns_addon_version
  resolve_conflicts_on_create    = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.worker-node-group_4
  ]
}

#### VPC-CNI ######
resource "aws_eks_addon" "vpc-cni" {
  cluster_name                   = aws_eks_cluster.cluster.name
  addon_name                     = "vpc-cni"
  addon_version                  = var.vpc-cni_addon_version
  resolve_conflicts_on_create    = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.worker-node-group_4
  ]
}

#### EBS-CSI Driver ######
# resource "aws_eks_addon" "ebs-csidriver" {
#   cluster_name                   = aws_eks_cluster.cluster.name
#   addon_name                     = "aws-ebs-csi-driver"
#   addon_version                  = var.ebs-csidriver_addon_version
#   resolve_conflicts_on_create    = "OVERWRITE"

#   depends_on = [
#     aws_eks_node_group.worker-node-group_4
#   ]
# }


###########  EKS Addons-node-group #################

####### Node group 4 ###########
resource "aws_eks_node_group" "worker-node-group_4" {
  cluster_name    = var.name
  node_group_name = "${var.name}-worker-node-02"
  node_role_arn   = var.managed_workers_arn
  subnet_ids      = var.private_subnet_ids
  launch_template {
   name = var.eks_lt_name
   version = var.eks_lt_latest_version
}
  scaling_config {
    desired_size = var.worker_desired_size
    max_size     = var.worker_max_size
    min_size     = var.worker_min_size
  }
  tags = {
    Name = var.name
    "kubernetes.io/cluster/aws_eks_cluster.cluster" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/aws_eks_cluster.cluster" = "owned"
  }
  depends_on = [
    aws_eks_cluster.cluster,
    local_file.aws_auth_configmap
  ]
lifecycle {
    create_before_destroy = true
  }
}
