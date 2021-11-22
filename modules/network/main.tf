


data "aws_availability_zones" "available" {}


#--------------------------------------------------------------------------
#                 SETUP VPC AND INTERNET GATEWAY
#--------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env} + Vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}


#--------------------------------------------------------------------------
#                       CREATE ROUTING TABLES
#--------------------------------------------------------------------------
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Routing Public Subnets"
  }
}

resource "aws_route_table" "private_subnets" {
  count  = var.num_of_zones
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main[*].id, count.index)
  }
  depends_on = [aws_nat_gateway.main]

}

resource "aws_route_table_association" "public_subnets" {
  count          = var.num_of_zones
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)

}

resource "aws_route_table_association" "private_subnets" {
  count          = var.num_of_zones
  route_table_id = element(aws_route_table.private_subnets[*].id, count.index)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}

#---------------------------------------------------------------------------
#                         ELLASTIC IP AND NAT
#---------------------------------------------------------------------------


resource "aws_eip" "main" {
  count      = var.num_of_zones
  vpc        = true
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.num_of_zones
  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "NAT number ${count.index}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

#---------------------------------------------------------------------------
#                       PRIVATE AND PUBLIC SUBNETS
#---------------------------------------------------------------------------

resource "aws_subnet" "public_subnets" {
  count                   = var.num_of_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_public_subnets, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "Main Public Subnet in ${data.aws_availability_zones.available.names[count.index]}"
    #Name = "Main Public Subnet"
  }
}


resource "aws_subnet" "private_subnets" {
  count                   = var.num_of_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_private_subnets, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "Main Private Subnet"
  }
}


resource "aws_network_interface" "main" {
  subnet_id = aws_subnet.public_subnets[0].id
  security_groups = [module.http_80_security_group.security_group_id]
}


#---------------------------------------------------------------------------

