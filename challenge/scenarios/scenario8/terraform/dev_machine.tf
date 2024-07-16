data "aws_ami" "gitlabubuntu" {

  filter {
    name   = "name"
    values = ["GitLab CE 15.3.3"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["782774275127"] # GitLab
}

resource "aws_network_interface" "dev" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.0.1.10"] 
}

resource "aws_security_group" "ingress-all-test" {
name = "allow-all-sg"
vpc_id = module.vpc.vpc_id
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port = 22
    protocol = "tcp"
  }

ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port = 80
    protocol = "tcp"
  }

// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "dev" {
  ami                  = data.aws_ami.gitlabubuntu.id
  instance_type        = var.gitlab_ec2_type
  user_data            = templatefile("${path.module}/../assets/dev-machine/provisiontoken.sh", { set_token = var.gitlab_token })

  tags = {
    Name        = "dev-instance",
    Environment = "dev"
  }
}

locals {
  terraform_tfvars = <<-EOT
    public_ip = "${aws_instance.dev.public_ip}"
    gitlab_token = "${var.gitlab_token}"
    scenario-name = "${var.scenario-name}"
    repo_readonly_username = "${var.repo_readonly_username}"
    gitlab_hook = "${aws_lambda_function_url.GitLabHook.function_url}"
    userid = [
    %{ for userid in local.users.*.userid ~}
    "${userid}",
    %{ endfor ~}
    ]
    keys = [
    %{ for key in local.keys_array ~}
    "${key}",
    %{ endfor ~}
    ]
  EOT
}

resource "local_file" "terraform_tfvars" {
  depends_on = [
    aws_instance.dev
  ]
  filename = "${path.module}/gitlab_module/terraform.tfvars"
  content  = local.terraform_tfvars
}



resource "null_resource" "gitlabapi_readiness" {
  depends_on = [
    aws_instance.dev
  ]

  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    
    command     = <<BASH
    COUNT=1
    APIREADY_SUCCESS=0
    while [[ $APIREADY_SUCCESS -ne 1 ]]; do
      echo "Start check GitLab API readiness loop $COUNT"
      sleep 20
      STATUS=$(curl -s -o /dev/null -w ''%%{http_code}'' -c 5 -m 10 http://${aws_instance.dev.public_ip}/api/v4/version --header "Private-Token: ${var.gitlab_token}")
      echo "Status: $STATUS"
      if [[ $STATUS -eq "200" ]]; then
        echo "API ready"
        APIREADY_SUCCESS=1
      fi
      if [[ $COUNT -ge 100 ]]; then
        break
      else
        let COUNT++
      fi
    done
    cd ./gitlab_module
    rm -rf .terraform*
    rm -rf terraform.tfstate
    terraform init
    terraform apply -auto-approve 
    cd ..
BASH
  }
}
