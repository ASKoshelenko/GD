# IAM Role
resource "aws_iam_role" "sc4-ec2-role" {
  name = "sc4-ec2-role"
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
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}
# IAM Role Policy
resource "aws_iam_role_policy" "sc4-ec2-role-policy" {
  name = "sc4-ec2-role-policy"
  role = aws_iam_role.sc4-ec2-role.id
  policy = <<POLICY
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
            "${aws_s3_bucket.sc4-secret-s3-bucket.arn}",
            "${aws_s3_bucket.sc4-secret-s3-bucket.arn}/*"
          ]
        },
        {
          "Sid": "Terraform1",
          "Action": "s3:ListAllMyBuckets",
          "Effect": "Allow",
          "Resource": "*"
        }
    ]
}
POLICY
}
# IAM Instance Profile
resource "aws_iam_instance_profile" "sc4-ec2-instance-profile" {
  name = "sc4-ec2-instance-profile"
  role = aws_iam_role.sc4-ec2-role.name
}
# Security Groups
resource "aws_security_group" "sc4-ec2-ssh-security-group" {
  name = "sc4-ec2-ssh"
  description = "${var.scenario-name} Security Group for EC2 Instance over SSH"
  vpc_id = aws_vpc.sc4-vpc.id
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
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc4-ec2-ssh-epam-by-ru" {
#   name = "sc4-ec2-ssh-epam-by-ru"
#   description = "Scenario 4 Security Group for EC2 Instance over SSH by-ru"
#   vpc_id = aws_vpc.sc4-vpc.id
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
#     Name = "sc4-ec2-ssh-epam-by-ru"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc4-ec2-ssh-epam-europe" {
#   name = "sc4-ec2-ssh-epam-europe"
#   description = "Scenario 4 Security Group for EC2 Instance over SSH europe"
#   vpc_id = aws_vpc.sc4-vpc.id
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
#     Name = "sc4-ec2-ssh-epam-europe"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc4-ec2-ssh-epam-world" {
#   name = "sc4-ec2-ssh-epam-world"
#   description = "Scenario 4 Security Group for EC2 Instance over SSH world"
#   vpc_id = aws_vpc.sc4-vpc.id
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
#     Name = "sc4-ec2-ssh-epam-world"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

resource "aws_security_group" "sc4-ec2-http-security-group" {
  name = "sc4-ec2-http"
  description = "${var.scenario-name} Security Group for EC2 Instance over HTTP"
  vpc_id = aws_vpc.sc4-vpc.id
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
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc4-ec2-http-epam-by-ru" {
#   name = "sc4-ec2-http-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for by-ru"
#   vpc_id = aws_vpc.sc4-vpc.id
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
# resource "aws_security_group" "sc4-ec2-http-epam-europe" {
#   name = "sc4-ec2-http-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for europe"
#   vpc_id = aws_vpc.sc4-vpc.id
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

# resource "aws_security_group" "sc4-ec2-http-epam-world" {
#   name = "sc4-ec2-http-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over HTTP for world"
#   vpc_id = aws_vpc.sc4-vpc.id
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

#AWS Key Pair
resource "aws_key_pair" "sc4-ec2-key-pair" {
  key_name = "sc4-ec2-key-pair"
  public_key = file(var.ssh-public-key-for-ec2)
}

# AWS Key Pair
resource "aws_key_pair" "root_key_pair" {
  key_name = "admin4"
  public_key = file(var.ssh-public-key-admin4)
}


# EC2 Instance
resource "aws_instance" "sc4-ubuntu-ec2" {
    ami = var.ami
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.sc4-ec2-instance-profile.name
    subnet_id = aws_subnet.sc4-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc4-ec2-ssh-security-group.id,
        aws_security_group.sc4-ec2-http-security-group.id,
        # aws_security_group.sc4-ec2-ssh-epam-by-ru.id,
        # aws_security_group.sc4-ec2-ssh-epam-europe.id,
        # aws_security_group.sc4-ec2-ssh-epam-world.id,
        # aws_security_group.sc4-ec2-http-epam-by-ru.id,
        # aws_security_group.sc4-ec2-http-epam-europe.id,
        # aws_security_group.sc4-ec2-http-epam-world.id
    ]
    key_name = aws_key_pair.sc4-ec2-key-pair.key_name
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    provisioner "file" {
      source = "../assets/ssrf_app/app.zip"
      destination = "/home/ubuntu/app.zip"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file(var.ssh-private-key-for-ec2)
        host = self.public_ip
      }
    }
    user_data = <<-EOF
        #!/usr/bin/env bash
        user=scadmin
        SUDOERPATH=/etc/sudoers.d/$user
        EDITPATH=/tmp/$${user}.edit
        apt-get update
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        apt-get install -y nodejs unzip
        apt install npm -y
        npm install http express needle command-line-args
        cd /home/ubuntu
        unzip app.zip -d ./app
        cd app
        sudo node ssrf-demo-app.js &
        echo -e "\n* * * * * root node /home/ubuntu/app/ssrf-demo-app.js &\n* * * * * root sleep 10; node /home/ubuntu/app/ssrf-demo-app.js &\n* * * * * root sleep 20; node /home/ubuntu/app/ssrf-demo-app.js &\n* * * * * root sleep 30; node /home/ubuntu/app/ssrf-demo-app.js &\n* * * * * root sleep 40; node /home/ubuntu/app/ssrf-demo-app.js &\n* * * * * root sleep 50; node /home/ubuntu/app/ssrf-demo-app.js &\n" >> /etc/crontab
        adduser --quiet --disabled-password --shell /bin/bash --home /home/$${user} $user
        mkdir /home/$${user}/.ssh
        echo ${aws_key_pair.root_key_pair.public_key} >> /home/$${user}/.ssh/authorized_keys
        touch $SUDOERPATH
        echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > $EDITPATH
        # verify sudoers file
        visudo -c -f $EDITPATH
        # apply settings
        if [ "$?" = "0" ] ; then

            # make bakup
            cp -f $SUDOERPATH $${SUDOERPATH}.back
            mv -f $EDITPATH $SUDOERPATH
        else

            # discard changes
            rm -f $EDITPATH
        fi        
        chown root:root /home/ubuntu/.ssh/authorized_keys
        chmod 644 /home/ubuntu/.ssh/authorized_keys
        chattr +a /home/ubuntu/.ssh/
        chmod -R 750 log
        deluser ubuntu adm
        deluser ubuntu dialout
        deluser ubuntu cdrom
        deluser ubuntu floppy
        deluser ubuntu audio
        deluser ubuntu dip
        deluser ubuntu video
        deluser ubuntu plugdev
        deluser ubuntu lxd
        deluser ubuntu sudo
        rm /etc/sudoers.d/90-cloud-init-users
        reboot
    EOF
    volume_tags = {
        Name = "${var.scenario-name}-EC2 Instance Root Device"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
    tags = {
        Name = "${var.scenario-name}-ubuntu-ec2"
        Stack = var.stack-name
        Scenario = var.scenario-name
        Protected = "True"
        Tip = "SSRF"
    }
}
