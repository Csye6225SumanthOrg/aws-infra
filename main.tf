resource "aws_vpc" "vpc_1" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.prefix_name}_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc_1.id
  count             = var.subnet_public_count
  cidr_block        = cidrsubnet(aws_vpc.vpc_1.cidr_block, var.slash_notion, count.index)
  availability_zone = data.aws_availability_zones.available.names[(count.index % length(data.aws_availability_zones.available.names))]
  tags = {
    Name = "${var.prefix_name}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_1.id
  count             = var.subnet_private_count
  cidr_block        = cidrsubnet(aws_vpc.vpc_1.cidr_block, var.slash_notion, count.index + var.subnet_public_count)
  availability_zone = data.aws_availability_zones.available.names[(count.index % length(data.aws_availability_zones.available.names))]
  tags = {
    Name = "${var.prefix_name}-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "${var.prefix_name}_vpc_1_gateway"
  }
}

resource "aws_route_table" "public_route_tb" {
  vpc_id = aws_vpc.vpc_1.id
  route {
    cidr_block = var.gateway_route
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.prefix_name}_public_route_table"
  }
}

resource "aws_route_table" "private_route_tb" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "${var.prefix_name}_private_route_table"
  }
}

resource "aws_route_table_association" "private_route_association" {
  count          = var.subnet_private_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_tb.id
}

resource "aws_route_table_association" "public_route_association" {
  count          = var.subnet_public_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_tb.id
}


resource "aws_security_group" "app_sg" {
  name = "applicaiton_security_group"
  description = "Allow TCP inbound traffic"
  vpc_id = aws_vpc.vpc_1.id
  
  tags = {
    Name = "app_security_group"
  }
  
}

resource "aws_security_group_rule" "ingress_rules" {
  security_group_id = aws_security_group.app_sg.id
  count = length(var.ingress_ports)
  type = "ingress"
  protocol = "tcp"
  from_port = var.ingress_ports[count.index]
  to_port = var.ingress_ports[count.index]
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_instance" "app_server" {
  ami = var.ami_id
  instance_type = "t2.micro"  
  associate_public_ip_address = true

  key_name = "ec2_key"
  subnet_id = aws_subnet.public_subnet[0].id
  disable_api_termination = true
  
  root_block_device {
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]


}
