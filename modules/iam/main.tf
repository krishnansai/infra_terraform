data "aws_partition" "current" {}
#Resource to create eks cluster role
resource "aws_iam_role" "cluster_role" {
  name = "${var.name}-${var.env}-cluster-role"

assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

tags = {
    Name = var.name
    ENV  = var.env
}
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster_role.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy" "devops_kms_access" {
  name = "devops-kms-access"
  role = aws_iam_role.cluster_role.id # replace with your role ID

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "kms:DescribeCustomKeyStores",
          "kms:ListKeys",
          "kms:DeleteCustomKeyStore",
          "kms:GenerateRandom",
          "kms:UpdateCustomKeyStore",
          "kms:*",
          "kms:ListAliases",
          "kms:DisconnectCustomKeyStore",
          "kms:CreateKey",
          "kms:ConnectCustomKeyStore",
          "kms:CreateCustomKeyStore"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt",
          "kms:*"
        ],
        "Resource": [
          "arn:aws:kms:*:${var.aws_account_id}:key/*",
          "arn:aws:kms:*:${var.aws_account_id}:alias/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "kms:*",
        "Resource": "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.key_id}"
      },
      {
        "Effect": "Allow",
        "Action": "kms:*",
        "Resource": [
          "arn:aws:kms:*:${var.aws_account_id}:key/*",
          "arn:aws:kms:*:${var.aws_account_id}:alias/*"
        ]
      }
    ]
  }
  EOF
}
# Resource to create eks worker node role
resource "aws_iam_role" "managed_workers" {
  name = "${var.name}-${var.env}-worker-node-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "cluster_s3access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "ec2_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "AutoScalingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "AmazonRoute53DNSPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.managed_workers.name
}
resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_role_policy" "set_name_tag" {
  name = "set_name_tag"
  role = aws_iam_role.managed_workers.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:CreateTags"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "describe_asg_policy" {
  name = "Describe-ASG"
  role = aws_iam_role.managed_workers.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:Describe*",
          "autoscaling:GetPredictiveScalingForecast"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "describe_ec2_policy" {
  name = "Describe-EC2"
  role = aws_iam_role.managed_workers.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:Describe*",
          "ec2:GetVerifiedAccessGroupPolicy",
          "ec2:GetVerifiedAccessEndpointPolicy",
          "ec2:GetVpnTunnelReplacementStatus",
          "ec2:SearchLocalGatewayRoutes",
          "ec2:GetTransitGatewayPolicyTableEntries",       
          "ec2:SearchTransitGatewayMulticastGroups",
          "ec2:GetIpamPoolAllocations",    
          "ec2:GetInstanceMetadataDefaults",
          "ec2:SearchTransitGatewayRoutes",
          "ec2:GetTransitGatewayAttachmentPropagations",
          "ec2:GetGroupsForCapacityReservation",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "ec2:GetTransitGatewayRouteTablePropagations",
          "ec2:ListSnapshotsInRecycleBin",
          "ec2:ListImagesInRecycleBin",
          "ec2:DescribeCarrierGateways",
          "ec2:GetTransitGatewayRouteTableAssociations",
          "ec2:GetVpnConnectionDeviceSampleConfiguration",
          "ec2:GetVpnConnectionDeviceTypes",
          "ec2:GetTransitGatewayPrefixListReferences",
          "ec2:GetVerifiedAccessInstanceWebAcl",
          "ec2:GetTransitGatewayPolicyTableAssociations",
          "ec2:GetTransitGatewayMulticastDomainAssociations",
          "ec2:DescribeLockedSnapshots"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.name}-${var.env}-worker-node-role"
  role = aws_iam_role.managed_workers.name
}



# # Note the cluster name set in the `Condition` of the policy.
# resource "aws_iam_role_policy" "aws-working_cluster_autoscaler_role_policy" {
#   name = "aws-working_cluster-autoscaler"
#   role = aws_iam_role.aws-working_cluster_autoscaler.id

#   policy = <<EOF
# {
# 	"Version": "2012-10-17",
# 	"Statement": [
# 		{
# 			"Sid": "VisualEditor0",
# 			"Effect": "Allow",
# 			"Action": [
# 				"autoscaling:SetDesiredCapacity",
# 				"autoscaling:TerminateInstanceInAutoScalingGroup"
# 			],
# 			"Resource": "*",
# 			"Condition": {
# 				"ForAllValues:StringEquals": {
# 					"aws:TagKeys": "k8s.io/cluster-autoscaler/eks-staging"
# 				}
# 			}
# 		},
# 		{
# 			"Sid": "VisualEditor1",
# 			"Effect": "Allow",
# 			"Action": [
# 				"ec2:DescribeImages",
# 				"ec2:GetInstanceTypesFromInstanceRequirements"
# 			],
# 			"Resource": "*",
# 			"Condition": {
# 				"ForAllValues:StringEquals": {
# 					"aws:TagKeys": "k8s.io/cluster-autoscaler/eks-staging"
# 				}
# 			}
# 		},
# 		{
# 			"Sid": "VisualEditor2",
# 			"Effect": "Allow",
# 			"Action": "eks:DescribeNodegroup",
# 			"Resource": "*",
# 			"Condition": {
# 				"ForAllValues:StringEquals": {
# 					"aws:TagKeys": "k8s.io/cluster-autoscaler/eks-staging"
# 				}
# 			}
# 		},
# 		{
# 			"Sid": "VisualEditor3",
# 			"Effect": "Allow",
# 			"Action": [
# 				"sts:GetSessionToken",
# 				"autoscaling:DescribeAutoScalingInstances",
# 				"autoscaling:DescribeAutoScalingGroups",
# 				"sts:DecodeAuthorizationMessage",
# 				"autoscaling:DescribeTags",
# 				"autoscaling:DescribeLaunchConfigurations",
# 				"ec2:DescribeLaunchTemplateVersions",
# 				"ec2:DescribeInstanceTypes",
# 				"sts:GetAccessKeyInfo",
# 				"sts:GetCallerIdentity",
# 				"sts:GetServiceBearerToken"
# 			],
# 			"Resource": "*"
# 		},
# 		{
# 			"Sid": "VisualEditor4",
# 			"Effect": "Allow",
# 			"Action": [
# 				"sts:*",
# 				"sts:AssumeRoleWithWebIdentity"
# 			],
# 			"Resource": [
# 				"arn:aws:iam::${var.aws_account_id}:user/*",
# 				"arn:aws:iam::${var.aws_account_id}:role/*"
# 			]
# 		}
# 	]
# }
# EOF
# }

# This role ARN will be specified in the Cluster Autoscaler Reckoner snippet.
# output "aws-working_cluster_autoscaler_role_arn" {
#   value = aws_iam_role.aws-working_cluster_autoscaler.arn
# }

