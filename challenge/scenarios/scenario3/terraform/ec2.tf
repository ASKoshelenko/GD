#Security Groups
resource "aws_security_group" "sc3-ec2-ssh-security-group" {
  name = "${var.scenario-name}-ec2-ssh"
  description = "${var.scenario-name} Security Group for EC2 Instance over SSH"
  vpc_id = aws_vpc.vpc.id
  ingress {
      from_port = 22
      to_port = 22
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
    Name = "${var.scenario-name}-ec2-ssh"
    Stack = var.stack-name
  }
}

# resource "aws_security_group" "sc3-ec2-ssh-epam-by-ru" {
#   name = "${var.scenario-name}-ec2-ssh-epam-by-ru"
#   description = "Scenario 3 Security Group for EC2 Instance over SSH by-ru"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_by_ru
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#           "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "sc3-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc3-ec2-ssh-epam-europe" {
#   name = "${var.scenario-name}-ec2-ssh-epam-europe"
#   description = "Scenario 3 Security Group for EC2 Instance over ssh for europe"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_europe
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#           "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "sc3-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc3-ec2-ssh-epam-world" {
#   name = "${var.scenario-name}-ec2-ssh-epam-world"
#   description = "Scenario 3 Security Group for EC2 Instance over ssh for world"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_world
#   }
#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = [
#           "0.0.0.0/0"
#       ]
#   }
#   tags = {
#     Name = "sc3-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

resource "aws_security_group" "sc3-ec2-http-https-security-group" {
  name = "${var.scenario-name}-ec2-http"
  description = "${var.scenario-name} Security Group for EC2 Instance over HTTP"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  ingress {
      from_port = 443
      to_port = 443
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
    Name = "${var.scenario-name}-ec2-http"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc3-ec2-http-epam-by-ru" {
#   name = "${var.scenario-name}-ec2-http-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for by-ru"
#   vpc_id = aws_vpc.vpc.id
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
# resource "aws_security_group" "sc3-ec2-http-epam-europe" {
#   name = "${var.scenario-name}-ec2-http-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for europe"
#   vpc_id = aws_vpc.vpc.id
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

# resource "aws_security_group" "sc3-ec2-http-epam-world" {
#   name = "${var.scenario-name}-ec2-http-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for world"
#   vpc_id = aws_vpc.vpc.id
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

# resource "aws_security_group" "sc3-ec2-https-epam-by-ru" {
#   name = "${var.scenario-name}-ec2-https-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTPS for by-ru"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#     from_port = 443
#     to_port = 443
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
# resource "aws_security_group" "sc3-ec2-https-epam-europe" {
#   name = "${var.scenario-name}-ec2-https-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTPS for europe"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#     from_port = 443
#     to_port = 443
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
#     Name = "${var.scenario-name}-ec2-https-europe"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

# resource "aws_security_group" "sc3-ec2-https-epam-world" {
#   name = "${var.scenario-name}-ec2-https-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTPS for world"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#     from_port = 443
#     to_port = 443
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
#     Name = "${var.scenario-name}-ec2-https-world"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

#EC2 Instance
resource "aws_instance" "ec2" {
  count = length(local.users)
  ami = var.am-image
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  disable_api_termination = true
  user_data = file("${path.module}/../assets/userdata.tpl")
  vpc_security_group_ids = [
      aws_security_group.sc3-ec2-ssh-security-group.id,
      aws_security_group.sc3-ec2-http-https-security-group.id,
      # aws_security_group.sc3-ec2-ssh-epam-by-ru.id,
      # aws_security_group.sc3-ec2-ssh-epam-europe.id,
      # aws_security_group.sc3-ec2-ssh-epam-world.id,
      # aws_security_group.sc3-ec2-http-epam-by-ru.id,
      # aws_security_group.sc3-ec2-http-epam-europe.id,
      # aws_security_group.sc3-ec2-http-epam-world.id,
      # aws_security_group.sc3-ec2-https-epam-by-ru.id,
      # aws_security_group.sc3-ec2-https-epam-europe.id,
      # aws_security_group.sc3-ec2-https-epam-world.id
  ]
  root_block_device {
      volume_type = "gp2"
      volume_size = 8
     delete_on_termination = true
  }
  volume_tags = {
      Name = "${var.scenario-name} EC2 Instance Root Device"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
  tags = {
      Name = "${var.scenario-name} Super-critical-security-server_EC2-Instance_${local.users[count.index].userid}"
      Stack = var.stack-name
      Scenario = var.scenario-name
      Protected = "True"
      Tip = "Your instance profile name is ${aws_iam_instance_profile.ec2-meek-instance-profile[count.index].name}"
  }
}
