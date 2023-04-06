variable "region" {
  type    = string
  default = "us-east-1"
}
variable "profile" {
  type    = string
  default = "dev"
}

variable "domain_name" {
  type    = string
  default = "prod.sumanth.me"
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
  default = [22, 7070]
}

variable "ingress_ports_lb" {
  type    = list(number)
  default = [80, 443]
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "db_password" {
  type    = string
  default = "Asdqwe5640"
}

variable "db_identifier" {
  type    = string
  default = "csye6225"
}
variable "db_name" {
  type    = string
  default = "csye6225"
}

variable "db_user" {
  type    = string
  default = "csye6225"
}

variable "db_port" {
  type    = string
  default = "5432"
}


