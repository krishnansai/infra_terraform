# replace the data "template_file" block with Terraform's built-in templatefile function
locals {
  instance_profile_arn = var.managed_workers_arn
  root_device_mappings = tolist(data.aws_ami.eks_image.block_device_mappings)[0]
  autoscaler_tags      = var.cluster_autoscaler ? { "k8s.io/cluster-autoscaler/enabled" = "true", "k8s.io/cluster-autoscaler/${var.name}" = "owned" } : {}
  eks_tags    = { "Name" = "${var.name}-${var.env}" }
  tags                 = merge(var.tags, { "kubernetes.io/cluster/${var.name}" = "owned"}, local.autoscaler_tags, local.eks_tags)
  labels               = merge(var.labels)

  config = templatefile("${path.root}/templates/userdata.sh.tpl", {
    cluster_name    = var.cluster_name
    cluster_endpoint = var.cluster_endpoint
    cluster_ca_data  = var.certificate_authority_data
    cluster_region  = var.region
    node_labels     = join("\n", [for label, value in local.labels : "\"${label}\" = \"${value}\""])
    node_taints     = join("\n", [for taint, value in var.taints : "\"${taint}\" = \"${value}\""])
  })
}
# Data block to fetch the AMI information
data "aws_ami" "eks_image" {
  filter {
    name   = "image-id"
    values = [var.eks_ami_id]
  }
}


resource "aws_launch_template" "eks_lt" {
  name_prefix            = "aws-${var.env}"
  update_default_version = true
  block_device_mappings {
    device_name = local.root_device_mappings.device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  instance_type = var.instance_size

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [var.aws_security_group_worker_node_id]
  }

   image_id      = var.eks_ami_id
   user_data     = base64encode(local.config)

 tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
  tags = local.tags

 key_name = var.key_name

  lifecycle {
    create_before_destroy = true
  }
}