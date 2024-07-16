#IAM Role
resource "aws_iam_role" "sc2-ec2-banking" {
  name = "sc2-ec2-banking"
  path  = "/${var.scenario-name}/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "sc2-ec2-banking"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}

resource "aws_iam_policy" "s3-read-access" {
  name = "sc2-s3-read-access"
  description = "policy to get secret from secure S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.cardholder-data-bucket.arn}",
        "${aws_s3_bucket.cardholder-data-bucket.arn}/*"
      ]
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    }
  ]
}
EOF
}

#IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "sc2-ec2-banking-policy-attachment-s3" {
  role = aws_iam_role.sc2-ec2-banking.name
  policy_arn = aws_iam_policy.s3-read-access.arn
}

#IAM Instance Profile
resource "aws_iam_instance_profile" "sc2-ec2-instance-profile" {
  name = "sc2-ec2-instance-profile"
  role = aws_iam_role.sc2-ec2-banking.name
}

#Security Groups
resource "aws_security_group" "sc2-ec2-ssh-security-group" {
  name = "sc2-ec2-ssh"
  description = "Scenario 2 Security Group for EC2 Instance over SSH"
  vpc_id = aws_vpc.sc2-vpc.id
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
    Name = "sc2-ec2-ssh"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_security_group" "sc2-ec2-http-security-group" {
  name = "sc2-ec2-http"
  description = "Scenario 2 Security Group for EC2 Instance over HTTP"
  vpc_id = aws_vpc.sc2-vpc.id
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
    Name = "sc2-ec2-http"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc2-ec2-ssh-epam-by-ru" {
#   name = "sc2-ec2-ssh-epam-by-ru"
#   description = "Scenario 2 Security Group for EC2 Instance over SSH by-ru"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_by_ru.*
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
#     Name = "sc2-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc2-ec2-ssh-epam-europe" {
#   name = "sc2-ec2-ssh-epam-europe"
#   description = "Scenario 2 Security Group for EC2 Instance over ssh for europe"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_europe.*
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
#     Name = "sc2-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc2-ec2-ssh-epam-world" {
#   name = "sc2-ec2-ssh-epam-world"
#   description = "Scenario 2 Security Group for EC2 Instance over ssh for world"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_world.*
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
#     Name = "sc2-ec2-ssh"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc2-ec2-http-epam-by-ru" {
#   name = "sc2-ec2-http-epam-by-ru"
#   description = "Scenario 2 Security Group for EC2 Instance over HTTP for by-ru"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 80
#       to_port = 80
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_by_ru.*
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
#     Name = "sc2-ec2-http"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc2-ec2-http-epam-europe" {
#   name = "sc2-ec2-http-epam-europe"
#   description = "Scenario 2 Security Group for EC2 Instance over HTTP for europe"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 80
#       to_port = 80
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_europe.*
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
#     Name = "sc2-ec2-http"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc2-ec2-http-epam-world" {
#   name = "sc2-ec2-http-epam-world"
#   description = "Scenario 2 Security Group for EC2 Instance over HTTP for world"
#   vpc_id = aws_vpc.sc2-vpc.id
#   ingress {
#       from_port = 80
#       to_port = 80
#       protocol = "tcp"
#       cidr_blocks = local.cidrs_world.*
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
#     Name = "sc2-ec2-http"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

#AWS Key Pair
resource "aws_key_pair" "sc2-ec2-key-pair" {
  key_name = "sc2-ec2-key-pair"
  public_key = file(var.ssh-public-key-for-ec2)
}
#EC2 Instance
resource "aws_instance" "ec2" {
    ami = var.am-image
    instance_type = "t3.small"
    iam_instance_profile = aws_iam_instance_profile.sc2-ec2-instance-profile.name
    subnet_id = aws_subnet.sc2-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc2-ec2-ssh-security-group.id,
        aws_security_group.sc2-ec2-http-security-group.id,
        # aws_security_group.sc2-ec2-ssh-epam-by-ru.id,
        # aws_security_group.sc2-ec2-ssh-epam-europe.id,
        # aws_security_group.sc2-ec2-ssh-epam-world.id,
        # aws_security_group.sc2-ec2-http-epam-by-ru.id,
        # aws_security_group.sc2-ec2-http-epam-europe.id,
        # aws_security_group.sc2-ec2-http-epam-world.id
    ]
    key_name = aws_key_pair.sc2-ec2-key-pair.key_name
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    provisioner "file" {
      source = "../assets/proxy.com"
      destination = "/home/ubuntu/proxy.com"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file(var.ssh-private-key-for-ec2)
        host = self.public_ip
      }
    }
    user_data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y nginx
        ufw allow 'Nginx HTTP'
        cp /home/ubuntu/proxy.com /etc/nginx/sites-enabled/proxy.com
        rm /etc/nginx/sites-enabled/default
        systemctl restart nginx
        EOF
    volume_tags = {
        Name = "${var.scenario-name} EC2 Instance Root Device"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
    tags = {
        Name = "${var.scenario-name}-ec2-vulnerable-proxy-server"
        Stack = var.stack-name
        Scenario = var.scenario-name
        Protected = "True"
    }
}