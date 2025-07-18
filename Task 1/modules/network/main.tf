locals {
  vpcs = { for vpc in var.vpcs : vpc.name => vpc }

  subnets = {
    for subnet in flatten([
      for vpc in var.vpcs : [
        for subnet in vpc.subnets : merge(subnet, {
          vpc_name = vpc.name
        })
      ]
    ]) : subnet.name => subnet
  }

  test = {for k, v in local.vpcs : k => v}
}

resource "aws_vpc" "terraform" {
  for_each = local.vpcs

  cidr_block = each.value.vpc_cidr_block
  tags = {
    Name = each.value.name
  }
}

locals {
  first_public_subnet = keys(local.public_subnets)[0]
  public_subnets = {
    for name, subnet in local.subnets : 
    name => subnet 
    if can(regex("public", name))
  }

  private_subnets = {
    for name, subnet in local.subnets : 
    name => subnet 
    if can(regex("private", name))
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  for_each = local.vpcs

  vpc_id = aws_vpc.terraform[each.key].id
  tags = {
    Name = "${each.value.name}-igw"
  }
}

# NAt Gateway
resource "aws_eip" "nat" {
  for_each = length(local.private_subnets) > 0 ? local.vpcs : null

  domain     = "vpc"
  tags = {
    Name = "${each.value.name}-eip"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nt" {
  for_each = length(local.private_subnets) > 0 ? local.vpcs : null

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.subnets[local.first_public_subnet].id
  depends_on    = [aws_internet_gateway.gw]
  tags          = { Name = "${each.value.name}-nat-gateway" }
}

# Subnets Provision
resource "aws_subnet" "subnets" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.terraform[each.value.vpc_name].id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = can(regex("public", each.value.name)) ? true : false

  tags = {
    Name = each.value.name
  }
}

# Public RT
resource "aws_route_table" "public" {
  for_each = local.vpcs

  vpc_id = aws_vpc.terraform[each.key].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[each.key].id
  }
  tags = { Name = "${each.value.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public[each.value.vpc_name].id
}

# Private RT
resource "aws_route_table" "private" {
  for_each = local.vpcs

  vpc_id = aws_vpc.terraform[each.key].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nt[each.key].id
  }
  tags = { Name = "${each.value.name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private[each.value.vpc_name].id
}