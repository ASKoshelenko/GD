#IAM Role
resource "aws_iam_role" "sc6-ec2-role" {
  name = "sc6-ec2-role"
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
      Name = "${var.scenario-name}-ec2-role"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}

# Iam Role Policy
resource "aws_iam_role_policy" "sc6-ec2-role-policy" {
  name = "sc6-ec2-role-policy"
  role = aws_iam_role.sc6-ec2-role.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "lambda:ListFunctions",
                "lambda:GetFunction",
                "rds:DescribeDBInstances"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}
# #IAM Role Policy Attachment
# resource "aws_iam_policy_attachment" "sc6-ec2-role-policy-attachment" {
#   name = "sc6-ec2-role-policy-attachment"
#   roles = [
#       aws_iam_role.sc6-ec2-role.name
#   ]
#   policy_arn = aws_iam_policy.sc6-ec2-role-policy.arn
# }

#IAM Instance Profile
resource "aws_iam_instance_profile" "sc6-ec2-instance-profile" {
  name = "sc6-ec2-instance-profile"
  role = aws_iam_role.sc6-ec2-role.name
}

#Security Groups
resource "aws_security_group" "sc6-ec2-ssh-security-group" {
  name = "sc6-ec2-ssh"
  description = "${var.scenario-name} Security Group for EC2 Instance over SSH"
  vpc_id = aws_vpc.sc6-vpc.id
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
    Name = "sc6-ec2-ssh"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc6-ec2-ssh-epam-by-ru" {
#   name = "sc6-ec2-ssh-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH by-ru"
#   vpc_id = aws_vpc.sc6-vpc.id
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
#     Name = "sc6-ec2-ssh-epam-by-ru"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc6-ec2-ssh-epam-europe" {
#   name = "sc6-ec2-ssh-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH europe"
#   vpc_id = aws_vpc.sc6-vpc.id
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
#     Name = "sc6-ec2-ssh-epam-europe"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc6-ec2-ssh-epam-world" {
#   name = "sc6-ec2-ssh-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH world"
#   vpc_id = aws_vpc.sc6-vpc.id
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
#     Name = "sc6-ec2-ssh-epam-world"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

# AWS Key Pair
resource "aws_key_pair" "sc6-ec2-key-pair" {
  key_name = "sc6-ec2-key-pair"
  public_key = file(var.ssh-public-key-for-ec2)

}
# AWS Key Pair
resource "aws_key_pair" "root_key_pair" {
  key_name = "admin6"
  public_key = file(var.ssh-public-key-admin6)
}

# EC2 Instance
resource "aws_instance" "sc6-ubuntu-ec2" {
    ami = "ami-0718a1ae90971ce4d"
    instance_type = "t3.small"
    iam_instance_profile = aws_iam_instance_profile.sc6-ec2-instance-profile.name
    subnet_id = aws_subnet.sc6-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc6-ec2-ssh-security-group.id,
        # aws_security_group.sc6-ec2-ssh-epam-by-ru.id,
        # aws_security_group.sc6-ec2-ssh-epam-europe.id,
        # aws_security_group.sc6-ec2-ssh-epam-world.id
    ]
    key_name = aws_key_pair.sc6-ec2-key-pair.key_name
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    user_data = <<-EOF
      #!/bin/bash
      user=scadmin
      SUDOERPATH=/etc/sudoers.d/$user
      EDITPATH=/tmp/$${user}.edit
      apt-get update
      apt-get install awscli -y
      apt-get install -y postgresql-client
      psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc6-psql-rds.endpoint}/${var.rds-database-name} \
      -c '\d;'
      psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc6-psql-rds.endpoint}/${var.rds-database-name} \
      -c "select * from sensitive_information;"
      adduser --quiet --disabled-password --shell /bin/bash --home /home/$${user} $user
      mkdir /home/$${user}/.ssh
      export AWS_DEFAULT_REGION=${var.region}
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
        Name = "${var.scenario-name} EC2 Instance Root Device"
        Stack = var.stack-name
        Scenario = var.scenario-name
        Protected = "True"
    }
    tags = {
        Name = "sc6-ec2"
        Stack = var.stack-name
        Scenario = var.scenario-name
        Protected = "True"
    }
}

# EC2 Instance
resource "aws_instance" "service-ec2" {
    ami = "ami-0718a1ae90971ce4d"
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.sc6-ec2-instance-profile.name
    subnet_id = aws_subnet.sc6-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc6-ec2-ssh-security-group.id
    ]
    key_name = aws_key_pair.sc6-ec2-key-pair.key_name
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    user_data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y postgresql-client
        user_name=(${join (" ", local.userid_array)})
        key=(${join (" ", random_id.secret_key.*.hex)})
        psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc6-psql-rds.endpoint}/${var.rds-database-name} \
        -c "CREATE TABLE sensitive_information (name VARCHAR(100) NOT NULL, value VARCHAR(100) NOT NULL);"
        for ((i=0; i < $${#user_name[@]}; i++))
        do
          psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc6-psql-rds.endpoint}/${var.rds-database-name} \
          -c "INSERT INTO sensitive_information (name,value) VALUES ('Key_$${i}', '$${user_name[i]}$${key[i]}');"
        done
        sleep 30
        shutdown now
        EOF
    volume_tags = {
        Protected = "True"
    }
    tags = {
        Name = "serviceForRDS6"
        Protected = "True"
    }
}
