#Security Groups
resource "aws_security_group" "sc5-lb-http-security-group" {
  name = "sc5-lb-http"
  description = "${var.scenario-name} Security Group for Application Load Balancer over HTTP"
  vpc_id = aws_vpc.sc5-vpc.id
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = var.cg_whitelist
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "sc5-lb-http"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc5-ec2-lb-epam-by-ru" {
#   name = "sc5-ec2-lb-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for by-ru"
#   vpc_id = aws_vpc.sc5-vpc.id
#   ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = local.cidrs_by_ru
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#         "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "${var.scenario-name}-ec2-http-by-ru"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc5-ec2-lb-epam-europe" {
#   name = "sc5-ec2-lb-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for europe"
#   vpc_id = aws_vpc.sc5-vpc.id
#   ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = local.cidrs_europe
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#         "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "${var.scenario-name}-ec2-http-europe"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

# resource "aws_security_group" "sc5-ec2-lb-epam-world" {
#   name = "sc5-ec2-lb-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for world"
#   vpc_id = aws_vpc.sc5-vpc.id
#   ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = local.cidrs_world
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#         "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "${var.scenario-name}-ec2-http-world"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

#Target Group
resource "aws_lb_target_group" "sc5-target-group" {
  name = "sc5-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.sc5-vpc.id
  target_type = "instance"
  tags = {
    Name = "sc5-target-group"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
#Target Group Attachment
resource "aws_lb_target_group_attachment" "sc5-target-group-attachment" {
  target_group_arn = aws_lb_target_group.sc5-target-group.arn
  target_id = aws_instance.sc5-ubuntu-ec2.id
  port = 9000
  depends_on = [aws_eip_association.sc5-ubuntu-ec2-eip-association]
}
#Load Balancer Listener
resource "aws_lb_listener" "sc5-lb-listener" {
  load_balancer_arn = aws_lb.sc5-lb.arn
  port = 80
  default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.sc5-target-group.arn
  }
}

#Application Load Balancer
resource "aws_lb" "sc5-lb" {
  name = "sc5-lb"
  internal = false
  load_balancer_type = "application"
  ip_address_type = "ipv4"
  access_logs {
      bucket = aws_s3_bucket.sc5-logs-s3-bucket.bucket
      prefix = "sc5-lb-logs"
      enabled = true
  }
  security_groups = [
      aws_security_group.sc5-lb-http-security-group.id,
      # aws_security_group.sc5-ec2-lb-epam-world.id,
      # aws_security_group.sc5-ec2-lb-epam-by-ru.id,
      # aws_security_group.sc5-ec2-lb-epam-europe.id
  ]
  subnets = [
      aws_subnet.sc5-public-subnet-1.id,
      aws_subnet.sc5-public-subnet-2.id
  ]
  tags = {
      Name = "sc5-lb"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}