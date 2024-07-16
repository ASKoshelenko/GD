#AWS Key Pair
# resource "aws_security_group" "security-challenge" {
#   name = "ec2-security-challenge"
#   description = "security-challenge Group for EC2 Instance over ssh"
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       self = true
#       security_groups = [
#             "sg-0928da14a990ceb2f",
#             "sg-0a8aae081d9a75fae",
#             "sg-0b61fea55b29b704b"

#         ]
#   }
#     tags = {
#     Name = "cg-security-challenge"
#     Scenario = var.scenario-name
#   }
# }
resource "aws_key_pair" "sc7-ec2-key-pair" {
  key_name = "sc7-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh-public-key-for-ec2)
}

#EC2 Instance
resource "aws_instance" "sc7-ubuntu-ec2" {
    ami = "ami-0718a1ae90971ce4d"
    instance_type = "t3.micro"
    key_name = aws_key_pair.sc7-ec2-key-pair.key_name
    vpc_security_group_ids = [
        # aws_security_group.security-challenge.id
        "sg-0928da14a990ceb2f",
        "sg-0a8aae081d9a75fae",
        "sg-0b61fea55b29b704b"
    ]

    user_data = <<-EOF
        #!/bin/bash
        apt-get update
        cd /home/ubuntu
        sudo adduser --quiet --disabled-password --shell /bin/bash --home /home/firstuser firstuser
        sudo mkdir /home/firstuser/.ssh
        sudo echo ${aws_key_pair.sc7-ec2-key-pair.public_key} >> /home/firstuser/.ssh/authorized_keys
        sudo usermod -aG sudo firstuser
        sudo usermod -aG adm firstuser
        sudo choun root:root /home/ubuntu/.ssh/authorized_keys
        sudo chattr +i /home/ubuntu/.ssh/authorized_keys
        sudo chmod -R 750 log
        sudo deluser ubuntu adm
        sudo deluser ubuntu dialout
        sudo deluser ubuntu cdrom
        sudo deluser ubuntu floppy
        sudo deluser ubuntu audio
        sudo deluser ubuntu dip
        sudo deluser ubuntu video
        sudo deluser ubuntu plugdev
        sudo deluser ubuntu lxd
        sudo deluser ubuntu sudo
        reboot
        EOF

    volume_tags = {
        Name = "EC2 Instance Root Device"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
    tags = {
        Protected = "True"
        Name = "sc7-ubuntu-ec2"
        Stack = var.stack-name
        Scenario = var.scenario-name
    }
}