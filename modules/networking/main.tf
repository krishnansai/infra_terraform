#### To fetch the VPC ###

resource "aws_vpc" "eks_network" {
  cidr_block = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = {
    Name = var.name
  }
}

# Internet gateway
resource "aws_internet_gateway" "eks_network_gateway" {
  vpc_id = aws_vpc.eks_network.id

  tags = {
    Name = var.name
  }
}

# NAT gateway and EIP ####
resource "aws_eip" "eks_network_nat_gateway" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.eks_network_gateway]

  tags = {
    Name = "${var.name}-nat-gateway"
  }
}

resource "aws_route_table" "eks_network_public" {
  vpc_id = aws_vpc.eks_network.id

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "internet-gateway" {
  route_table_id         = aws_route_table.eks_network_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_network_gateway.id
}

# resource "aws_default_route_table" "eks_network_private" {

resource "aws_route_table" "eks_network_private" {
  vpc_id = aws_vpc.eks_network.id
  tags = {
    Name = "${var.name}-private"
  }
}

############ Subnets Resources ###############
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count = var.az_counts

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  vpc_id                  = aws_vpc.eks_network.id
  map_public_ip_on_launch = true

  tags = {
    Name                             = "${var.name}-public-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/role/alb-ingress"    = "1"
    "subnet-type"                       = "public"
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "aws_route_table_association" "public" {
   count = var.az_counts

  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.eks_network_public.id
}

# Private subnets
resource "aws_subnet" "private" {
   count = var.private_az_counts
  cidr_block       = element(var.private_subnets, count.index)
  vpc_id                  = aws_vpc.eks_network.id
  map_public_ip_on_launch = false

  tags = {
    # Name                              = "${var.name}-private-${data.aws_availability_zones.available.names[count.index]}"
    "Name"                              = "${var.name}-private-${element(["1", "2", "2"], count.index % 3)}"  
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/role/alb-ingress"    = "1"
    "subnet-type"                       = "private"
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "aws_nat_gateway" "eks_network_nat_gateway" {
  allocation_id = aws_eip.eks_network_nat_gateway.id
  subnet_id      = aws_subnet.public.*.id[0]

  tags = {
    Name = var.name
  }
}

resource "aws_route" "nat-gateway" {
  route_table_id         = aws_route_table.eks_network_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_network_nat_gateway.id
}

resource "aws_route_table_association" "private" {
  count = var.az_counts

  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.eks_network_private.id
}

########### Security Group #####################
####### Security Group for EKS Cluster control plane ############

resource "aws_security_group" "control_plane" {
  name        = "eks-control-plane-${var.name}"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks_network.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self             = false
  }

  egress {
  description = "Allow Cluster API to node groups"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = []
  self        = true
  }

  egress {
    description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = []
    self        = true
    }

    egress {
    description = "Allow worker Kubelets and pods to receive communication on localhost"
    from_port   = 8080
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = []
    self        = true
    }  

  egress {
  description = "Cluster API to node kubelets"
  from_port   = 10250
  to_port     = 10250
  protocol    = "tcp"
  cidr_blocks = []
  self        = true
  }
  tags = {
    Name = "eks-control-plane-${var.name}"
  }
}


resource "aws_security_group_rule" "cluster-endpoint-connection" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "cluster-node" {
  source_security_group_id = aws_security_group.control_plane.id
  description       = "Allow Node groups to cluster commmunication"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group" "worker_node_sg" {
  name        = "${var.name}-worker-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.eks_network.id

  # DNS over UDP (port 53) to self whitelist
  ingress {
    description      = "Node to node CoreDNS UDP"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    self             = true  # Whitelist self SG
  }

  # DNS over TCP (port 53) to self whitelist
  ingress {
    description      = "Node to node CoreDNS"
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    self             = true  # Whitelist self SG
  }

  # All traffic to self whitelist
  ingress {
    description      = "Allow all traffic within the security group"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # "-1" means all protocols
    self             = true  # Whitelist self SG
  }

  # All traffic to VPC CIDR Range
  ingress {
    description      = "VPC CIDR"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # "-1" means all protocols
    cidr_blocks  = ["31.0.0.0/16"]  # Whitelist VPC CIDR Range
  }

  ingress {
    description      = "Cluster control plane SG for Cluster API to node groups"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.control_plane.id]
  }

  ingress {
    description      = "Cluster API to node kubelets"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    security_groups  = [aws_security_group.control_plane.id]
  }


  ingress {
    description      = "From control plane to 1025-65535"
    from_port        = 1025
    to_port          = 65535
    protocol         = "tcp"
    security_groups  = [aws_security_group.control_plane.id]
  }

  # Allow outbound traffic to all destinations
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-worker-node-sg"
  }
}

# ## security group rules for workernode ##### Newly Added

# resource "aws_security_group_rule" "k8s-traffic-eksstaging" {
#   from_port         = 0
#   protocol          = "-1"
#   security_group_id = aws_security_group.worker_node_sg.id
#   source_security_group_id = "sg-018ba03b7f9923e95"
#   to_port           = 0
#   type              = "ingress"
# }


# resource "aws_security_group_rule" "ingress" {
#   description       = "ingress-test-dev"
#   from_port         = 0
#   protocol          = "-1"
#   security_group_id = aws_security_group.worker_node_sg.id
#   source_security_group_id = "sg-0a3383ae8dcf55da6"
#   to_port           = 0
#   type              = "ingress"
# }


