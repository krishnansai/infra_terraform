provider "aws" {
  region = var.region
}


module "networking" {
  source            = "./modules/networking"
  vpc_cidr_block    = var.vpc_cidr_block
  name              = var.name
  az_counts         = var.az_counts
  private_az_counts = var.private_az_counts
  public_subnets    = var.public_subnets
  private_subnets   = var.private_subnets
}

module "iam" {
  source            = "./modules/iam"
  name              = var.name
  env               = var.env
  tags              = var.tags
  aws_account_id    = var.aws_account_id
  region            = var.region
  key_id            = var.key_id
  aws_iam_openid_connect_provider_arn = module.compute.aws_iam_openid_connect_provider_arn
  aws_iam_openid_connect_provider_url = module.compute.aws_iam_openid_connect_provider_url

}


module "launchtemplate" {
  source               = "./modules/launchtemplate"
  cluster_autoscaler   = var.cluster_autoscaler
  env                  = var.env
  name                 = var.name
  tags                 = var.tags
  labels               = var.labels
  taints               = var.taints
  region               = var.region
  instance_size        = var.instance_size
  root_volume_size     = var.root_volume_size
  eks_ami_id           = var.eks_ami_id
  key_name             = var.key_name
  aws_security_group_worker_node_id = module.networking.aws_security_group_worker_node_id
  managed_workers_arn               = module.iam.managed_workers_arn
  cluster_name                      = module.compute.cluster_name
  cluster_endpoint                  = module.compute.cluster_endpoint
  certificate_authority_data        = module.compute.certificate_authority_data
}
locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${module.iam.managed_workers_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::${var.aws_account_id}:role/devops_k8s_admins
      username: admin
      groups:
        - system:masters   
CONFIGMAPAWSAUTH
}
module "compute" {
  source               = "./modules/compute"
  name                 = var.name
  eks_version          = var.eks_version
  tags                 = var.tags
  key_id               = var.key_id
  kube-proxy_addon_version        = var.kube-proxy_addon_version
  coredns_addon_version           = var.coredns_addon_version
  vpc-cni_addon_version           = var.vpc-cni_addon_version
  ebs-csidriver_addon_version     = var.ebs-csidriver_addon_version
  log_retention        = var.log_retention
  worker_desired_size  = var.worker_desired_size
  worker_max_size      = var.worker_max_size
  worker_min_size      = var.worker_min_size
  private_subnet_ids   = module.networking.private_subnet_ids
  public_subnet_ids    = module.networking.public_subnet_ids
  cluster_role_arn     = module.iam.cluster_role_arn
  managed_workers_arn  = module.iam.managed_workers_arn
  eks_lt_name             = module.launchtemplate.eks_lt_name
  eks_lt_latest_version   = module.launchtemplate.eks_lt_latest_version
  config_map_aws_auth = local.config_map_aws_auth
  aws_security_group_control_plane_id = [module.networking.aws_security_group_control_plane_id] # Pass as a list
  depends_on = [
    module.networking.aws_nat_gateway_id,
  ]
}
