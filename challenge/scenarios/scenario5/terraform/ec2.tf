# IAM Role
resource "aws_iam_role" "sc5-ec2-role" {
  name = "sc5-ec2-role"
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
      Name = "sc5-ec2-role"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}

# IAM Policy for EC2-RDS
resource "aws_iam_role_policy" "sc5-ec2-rds-policy" {
  name = "sc5-ec2-rds-policy"
  role = aws_iam_role.sc5-ec2-role.id
  policy =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "rds:DescribeDBInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.sc5-secret-s3-bucket.arn}",
        "${aws_s3_bucket.sc5-secret-s3-bucket.arn}/*"
      ]
    },
    {
      "Action": "s3:ListAllMyBuckets",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "sc5-ec2-instance-profile" {
  name = "sc5-ec2-instance-profile"
  role = aws_iam_role.sc5-ec2-role.name
}

# Security Groups
resource "aws_security_group" "sc5-ec2-ssh-security-group" {
  name = "sc5-ec2-ssh"
  description = "${var.scenario-name} Security Group for EC2 Instance over SSH"
  vpc_id = aws_vpc.sc5-vpc.id
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
    Name = "sc5-ec2-ssh"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# resource "aws_security_group" "sc5-ec2-ssh-epam-by-ru" {
#   name = "sc5-ec2-ssh-epam-by-ru"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH by-ru"
#   vpc_id = aws_vpc.sc5-vpc.id
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
#     Name = "sc5-ec2-ssh-epam-by-ru"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc5-ec2-ssh-epam-europe" {
#   name = "sc5-ec2-ssh-epam-europe"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH europe"
#   vpc_id = aws_vpc.sc5-vpc.id
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
#     Name = "sc5-ec2-ssh-epam-europe"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }
# resource "aws_security_group" "sc5-ec2-ssh-epam-world" {
#   name = "sc5-ec2-ssh-epam-world"
#   description = "${var.scenario-name} Security Group for EC2 Instance over SSH world"
#   vpc_id = aws_vpc.sc5-vpc.id
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
#     Name = "sc5-ec2-ssh-epam-world"
#     Stack = var.stack-name
#     Scenario = var.scenario-name
#   }
# }

resource "aws_security_group" "sc5-ec2-http-security-group" {
  name = "sc5-ec2-http"
  description = "${var.scenario-name} Security Group for EC2 Instance over HTTP"
  vpc_id = aws_vpc.sc5-vpc.id
  ingress {
      from_port = 9000
      to_port = 9000
      protocol = "tcp"
      security_groups = [
          aws_security_group.sc5-lb-http-security-group.id
      ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = [
          aws_security_group.sc5-lb-http-security-group.id
      ]
  }
  tags = {
    Name = "sc5-ec2-http"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

# AWS Key Pair
resource "aws_key_pair" "sc5-ec2-key-pair" {
  key_name = "sc5-ec2-key-pair"
  public_key = file(var.ssh-public-key-for-ec2)
}


# AWS Key Pair
resource "aws_key_pair" "root_key_pair" {
  key_name = "admin5"
  public_key = file(var.ssh-public-key-admin5)
}

# EC2 Instance
resource "aws_instance" "sc5-ubuntu-ec2" {
    ami = "ami-0718a1ae90971ce4d"
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.sc5-ec2-instance-profile.name
    subnet_id = aws_subnet.sc5-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc5-ec2-ssh-security-group.id,
        aws_security_group.sc5-ec2-http-security-group.id,
        # aws_security_group.sc5-ec2-ssh-epam-by-ru.id,
        # aws_security_group.sc5-ec2-ssh-epam-europe.id,
        # aws_security_group.sc5-ec2-ssh-epam-world.id
    ]
    key_name = aws_key_pair.sc5-ec2-key-pair.key_name
    root_block_device {
        volume_type = "gp2"
        volume_size = 8
        delete_on_termination = true
    }
    provisioner "file" {
      source = "../assets/rce_app/app.zip"
      destination = "/home/ubuntu/app.zip"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file(var.ssh-private-key-for-ec2)
        host = self.public_ip
      }
    }
    user_data = <<-EOF
        #!/bin/bash
        user=scadmin
        SUDOERPATH=/etc/sudoers.d/$user
        EDITPATH=/tmp/$${user}.edit
        export AWS_DEFAULT_REGION=${var.region}
        apt-get update
        apt install awscli -y
        curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
        apt-get install -y nodejs postgresql-client unzip
        sleep 15s
        cd /home/ubuntu
        unzip app.zip -d ./app
        cd app
        node index.js &
        echo "\set HISTFILE /dev/null" >> /home/ubuntu/.psqlrc
        echo 'unset HISTFILE' >> /etc/profile.d/disable.history.sh
        echo 'unset HISTFILE' >> /root/.bashrc
        echo -e "\n* * * * * root node /home/ubuntu/app/index.js &\n* * * * * root sleep 10; curl GET http://${aws_lb.sc5-lb.dns_name}/mkja1xijqf0abo1h9glg.html &\n* * * * * root sleep 10; node /home/ubuntu/app/index.js &\n* * * * * root sleep 20; node /home/ubuntu/app/index.js &\n* * * * * root sleep 30; node /home/ubuntu/app/index.js &\n* * * * * root sleep 40; node /home/ubuntu/app/index.js &\n* * * * * ubuntu sleep 50; node /home/ubuntu/app/index.js &\n" >> /etc/crontab
        echo -e "*/30 * * * * root /bin/rm -f \$(find / -type f -name db.txt)" >> /etc/crontab
        echo -e "*/30 * * * * root echo /dev/null> ~/.bash_history && history -c" >> /etc/crontab
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
        Name = "${var.scenario-name} EC2 Instance Root Device"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
    tags = {
        Protected = "True"
        Name = "sc5-ubuntu-ec2"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
}


# EC2 Instance
resource "aws_instance" "service-ec2-5" {
    ami = "ami-0718a1ae90971ce4d"
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.sc5-ec2-instance-profile.name
    subnet_id = aws_subnet.sc5-public-subnet-1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [
        aws_security_group.sc5-ec2-ssh-security-group.id
    ]
    key_name = aws_key_pair.sc5-ec2-key-pair.key_name
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
        psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc5-psql-rds.endpoint}/${var.rds-database-name} \
        -c "CREATE TABLE sensitive_information (name VARCHAR(100) NOT NULL, value VARCHAR(100) NOT NULL);"
        for ((i=0; i < $${#user_name[@]}; i++))
        do
          psql postgresql://${var.rds-username}:${var.rds-password}@${aws_db_instance.sc5-psql-rds.endpoint}/${var.rds-database-name} \
          -c "INSERT INTO sensitive_information (name,value) VALUES ('Key_$${i}', '$${user_name[i]}$${key[i]}');"
        done
        sleep 30
        shutdown now
        EOF
    volume_tags = {
        Protected = "True"
    }
    tags = {
        Name = "serviceForRDS5"
        Protected = "True"
    }
}


resource "aws_eip" "sc5-ubuntu-ec2-eip" {
  tags = {
        Name = "sc5-ubuntu-ec2-eip"
  }
}

resource "aws_eip_association" "sc5-ubuntu-ec2-eip-association" {
  instance_id = aws_instance.sc5-ubuntu-ec2.id
  allocation_id = aws_eip.sc5-ubuntu-ec2-eip.id
}
