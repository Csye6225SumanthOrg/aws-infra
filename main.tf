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


//create resource s3 bucket


resource "aws_s3_bucket" "s3_bucket" {
  bucket = "csye6225.${random_string.s3_bucket_name.id}.${var.prefix_name}"

  tags = {
    Name = "csye6225 - S3 bucket"
  }
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "random_string" "s3_bucket_name" {
  upper   = false
  lower   = true
  special = false
  length  = 3
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle_config" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {

    id = "lifecycle"
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }
    status = "Enabled"
  }
}


//RDS Creation

//database security group
resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_1.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


//rds instance..
resource "aws_db_instance" "db_instance" {
  allocated_storage      = 10
  identifier             = var.db_identifier
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "14.6"
  instance_class         = "db.t3.micro"
  username               = var.db_user
  password               = var.db_password
  multi_az               = false
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.aws_db_paramGroup.name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_private_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]

}

//parameter group 
resource "aws_db_parameter_group" "aws_db_paramGroup" {
  name   = "my-pg"
  family = "postgres14"
}

// subnet group 

resource "aws_db_subnet_group" "db_private_subnet_group" {
  name       = "db_private_subnet_group"
  subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]

  tags = {
    Name = "db subnet groups"
  }
}
//ec2 Instance
# resource "aws_instance" "app_server" {
#   ami                         = var.ami_id
#   instance_type               = "t2.micro"
#   associate_public_ip_address = true
#   key_name                    = "ec2_key"
#   subnet_id                   = aws_subnet.public_subnet[0].id
#   disable_api_termination     = true
#   iam_instance_profile        = aws_iam_instance_profile.ec2_role_profile.name



#   //user data script
#   user_data = <<EOF
#     #!/bin/bash
#                       #########################################################
#                       ######################USer Data Config###################
#                       #########################################################
#                       cd /home/ec2-user/webapp
#                       touch .env
                      
#                       echo "DB_USER=${aws_db_instance.db_instance.identifier}" >> .env
#                       echo "DB_NAME=${aws_db_instance.db_instance.db_name}" >> .env
#                       echo "DB_PORT=${var.db_port}" >> .env
#                       echo "APP_PORT=7070" >> .env
#                       echo "DB_HOSTNAME=${aws_db_instance.db_instance.address}" >> .env
#                       echo "DB_PASSWORD=${var.db_password}" >> .env
#                       echo "AWS_BUCKET_NAME=${aws_s3_bucket.s3_bucket.bucket}" >> .env


#                       #mkdir -p /home/ec2-user/webapp/logs
#                       #chmod 777 /home/ec2-user/webapp/logs
#                       sudo systemctl start app
#                       sudo systemctl status app
#                       sudo systemctl enable app

#                       sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#                       -a fetch-config \
#                       -m ec2 \
#                       -c file:/home/ec2-user/webapp/config/cloudwatch-config.json \
#                   -s
# EOF
#   root_block_device {
#     delete_on_termination = true
#     volume_size           = 50
#     volume_type           = "gp2"
#   }

#   vpc_security_group_ids = [aws_security_group.app_sg.id]


# }




//s3 bucket policy
#Create an IAM Policy
resource "aws_iam_policy" "aws_iam_policy_s3_access" {
  name        = "WebAppS3"
  description = "Provides permission to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}",
        "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/*"]
      },
    ]
  })

}


//creating an iam role for ec2 instance
resource "aws_iam_role" "aws_ec2_role" {
  name = "ec2_role_csye6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

//attaching the policy to role
resource "aws_iam_policy_attachment" "policy_role_attach" {
  name       = "policy_role_attach"
  roles      = [aws_iam_role.aws_ec2_role.name]
  policy_arn = aws_iam_policy.aws_iam_policy_s3_access.arn
}
resource "aws_iam_policy_attachment" "policy_role_attach2" {
  name       = "policy_role_attach"
  roles      = [aws_iam_role.aws_ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

//need to create an instance profile for ec2 role as it acts as a container for the created role
resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "aws_ec2_role_profile"
  role = aws_iam_role.aws_ec2_role.name
}

data "aws_route53_zone" "zone_name" {
  name         = var.domain_name
  private_zone = false
}


resource "aws_security_group" "load_balancer_sg" {
  name        = "load balancer"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.vpc_1.id

  tags = {
    Name = "load_balancer_group"
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# resource "aws_security_group_rule" "ingress_rules_loadBalancer" {
#   security_group_id = aws_security_group.load_balancer_sg.id
#   count             = length(var.ingress_ports_lb)
#   type              = "ingress"
#   protocol          = "tcp"
#   from_port         = var.ingress_ports_lb[count.index]
#   to_port           = var.ingress_ports_lb[count.index]
#   cidr_blocks       = ["0.0.0.0/0"]
# }

resource "aws_security_group" "app_sg" {
  name        = "applicaiton_security_group"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.vpc_1.id

  tags = {
    Name = "app_security_group"
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 7070
    to_port         = 7070
    protocol        = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "template_launch" {
  name = "EC2_launch_template"
  block_device_mappings {
    device_name = "/dev/xvdg"
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp2"
    }
  }
  disable_api_termination = true
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role_profile.name
  }
  image_id = var.ami_id
  instance_type = "t2.micro"
  key_name = "ec2_key"
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
    subnet_id = aws_subnet.public_subnet[0].id
    security_groups = [aws_security_group.app_sg.id]

  }
#  vpc_security_group_ids = [aws_security_group.app_sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "launch_template"
    }
  }
  lifecycle {
    prevent_destroy = false
  }
    user_data = base64encode(templatefile("${path.module}/userdata.sh", {
         DB_USER="${aws_db_instance.db_instance.identifier}"
         DB_NAME="${aws_db_instance.db_instance.db_name}"
         DB_PORT="${var.db_port}"
         APP_PORT="7070"
         DB_HOSTNAME="${aws_db_instance.db_instance.address}"
         DB_PASSWORD="${var.db_password}"
         AWS_BUCKET_NAME="${aws_s3_bucket.s3_bucket.bucket}"
  }))
}

resource "aws_autoscaling_group" "asg" {
  name                      = "autoscaling_name"
  max_size                  = 3
  min_size                  = 1
  desired_capacity = 1
  force_delete              = true
  default_cooldown  = 60

  launch_template {
    id      = aws_launch_template.template_launch.id
    version = "$Latest"
  }
  vpc_zone_identifier       = [for subnet in aws_subnet.public_subnet : subnet.id]

  target_group_arns = [aws_lb_target_group.target_group.arn]
  tag {
    key                 = "Application"
    value               = "WebApp"
    propagate_at_launch = true
  }

 
}



# resource "aws_autoscaling_policy" "asg_cpu_policy" {
#     name = "csye6225-asg-cpu-sw"
#     autoscaling_group_name = aws_autoscaling_group.asg.name
#     adjustment_type = "ChangeInCapacity"
#     estimated_instance_warmup = 60
#     policy_type = "TargetTrackingScaling"

#     target_tracking_configuration {
#         predefined_metric_specification {
#             predefined_metric_type = "ASGAverageCPUUtilization"
#          }
#         target_value = 2
#     }
# }

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scaleupalaram"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}


resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" { 
  alarm_name          = "scaledownalarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}


resource "aws_lb" "lb" {
  name               = "csye6225-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
#  enable_deletion_protection = false

  tags = {
    Application = "WebApp"
 }
}

resource "aws_lb_target_group" "target_group" {
  name     = "csye6225-lb-tg"
  port     = "7070"
  target_type = "instance"
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_1.id
  # health_check {
  #   healthy_threshold   = 3
  #   unhealthy_threshold = 3
  #   timeout             = 10
  #   interval            = 30
  #   path                = "/healthz"
  # }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}



resource "aws_route53_record" "server1-record" {
  zone_id = data.aws_route53_zone.zone_name.zone_id
  name    = var.domain_name
  type    = "A"
   alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}