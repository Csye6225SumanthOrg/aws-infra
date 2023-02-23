variable "region" {
  type    = string
  default = "us-east-1"
}
variable "profile" {
  type    = string
  default = "dev"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "gateway_route" {
  type    = string
  default = "0.0.0.0/0"
}
variable "slash_notion" {
  type    = number
  default = 8
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  // TODO: Auto-retrive availability zones
}

variable "subnet_public_count" {
  type    = number
  default = 3
}
variable "subnet_private_count" {
  type    = number
  default = 3
}

variable "prefix_name" {
  type    = string
  default = "dev"
}
data "aws_availability_zones" "available" {
  state = "available"
}


variable "ingress_ports" {
  type    = list(number)
  default = [22, 80, 443, 7070]
}


variable "ami_id" {
  type    = string
  default = "ami-0e150d85b63801002"
}
