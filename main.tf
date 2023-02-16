resource "aws_vpc" "vpc_1" {
  cidr_block = var.cidr_block
  tags = {
    Name = "vpc_1"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc_1.id
  count             = var.subnet_public_count
  cidr_block        = cidrsubnet(aws_vpc.vpc_1.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[(count.index % length(data.aws_availability_zones.available.names))]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_1.id
  count             = var.subnet_private_count
  cidr_block        = cidrsubnet(aws_vpc.vpc_1.cidr_block, 8, count.index + var.subnet_public_count)
  availability_zone = data.aws_availability_zones.available.names[(count.index % length(data.aws_availability_zones.available.names))]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "vpc_1_gateway"
  }
}

resource "aws_route_table" "public_route_tb" {
  vpc_id = aws_vpc.vpc_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_tb" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "private_route_association" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_tb.id
}

resource "aws_route_table_association" "public_route_association" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_tb.id
}