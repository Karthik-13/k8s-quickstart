data "aws_availability_zones" "available" {}

resource "aws_vpc" "cluster-vpc" {
  cidr_block           = "10.0.0.0/16"

  enable_dns_hostnames = true
  tags                 = merge({
                         Name = "k8s-cluster-vpc"
                         }, local.tags)
}

resource "aws_subnet" "cluster-vpc-subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.cluster-vpc.id
  cidr_block              = cidrsubnet("10.0.1.0/16", 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({
                            Name = "k8s-cluster-vpc-subnet-${count.index}"
                            }, local.tags)
}

resource "aws_internet_gateway" "cluster-vpc-igw" {
  vpc_id = aws_vpc.cluster-vpc.id
  tags   = merge({
           Name = "k8s-cluster-vpc-igw"
           }, local.tags)
}

# Provides a VPC routing table for cluster subnets.
# One is enough, we only have one IGW anyway.
resource "aws_route_table" "cluster-route-table" {
  vpc_id = aws_vpc.cluster-vpc.id

  tags   = merge({
           Name = "k8s-cluster-rtb"
           }, local.tags)
}

# Provides a routing table entry (a route) in a VPC routing table for cluster subnets.
resource "aws_route" "public" {
  route_table_id         = aws_route_table.cluster-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cluster-vpc-igw.id
}

# Provides resources that each create an association between a subnet and a routing table.
# One for each AZ.
resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)

  subnet_id      = element(aws_subnet.cluster-vpc-subnets.*.id, count.index)
  route_table_id = aws_route_table.cluster-route-table.id

  lifecycle {
    ignore_changes = [
      "id",
    ]
  }
}

# Provides a resource to manage the default AWS Security Group.
resource "aws_default_security_group" "cluster-default-sg" {
  vpc_id = aws_vpc.cluster-vpc.id

  tags   = merge({
           Name = "k8s-cluster-default-sg"
           }, local.tags)
}