# Look up available AZs.
##############################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC with two subnets and an internet gateway.
# Route all traffic fron the subnets through the internet gateway.
##############################################################################################

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "node_vpc_gateway" {
  vpc_id = aws_vpc.cluster_vpc.id
}

resource "aws_route_table" "node_routes" {
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.node_vpc_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.node_vpc_gateway.id
  }
}

resource "aws_subnet" "subnet_uno" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id     = aws_vpc.cluster_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "subnet_uno_table_association" {
  subnet_id = aws_subnet.subnet_uno.id
  route_table_id = aws_route_table.node_routes.id
}

resource "aws_subnet" "subnet_dos" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.cluster_vpc.id

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "subnet_dos_table_association" {
  subnet_id = aws_subnet.subnet_dos.id
  route_table_id = aws_route_table.node_routes.id
}

# Create a security group for the cluster control plane to restrict networking.
##############################################################################################

resource "aws_security_group" "cluster_group" {
  name        = "cluster-security-group"
  description = "Cluster control plane security group."
  vpc_id      = aws_vpc.cluster_vpc.id
}

resource "aws_security_group_rule" "cluster_to_internet" {
  security_group_id = aws_security_group.cluster_group.id
  description       = "Allow cluster all egress to the Internet."

  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_from_node" {
  security_group_id = aws_security_group.cluster_group.id
  description       = "Allow cluster to receive traffic from nodes."

  source_security_group_id = aws_security_group.node_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
}

# Create a security group for the nodes to restrict networking.
##############################################################################################

resource "aws_security_group" "node_group" {
  name        = "node-security-group"
  description = "Nodes security group."
  vpc_id      = aws_vpc.cluster_vpc.id
}

resource "aws_security_group_rule" "node_to_internet" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow nodes all egress to the Internet."

  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node_from_node" {
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow nodes to communicate with each other."

  source_security_group_id = aws_security_group.node_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
}

resource "aws_security_group_rule" "node_from_cluster" {
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow nodes to receive connections from the cluster (control-plane)."

  source_security_group_id = aws_security_group.cluster_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
}