resource "null_resource" "stop_instances" {
  count = length(local.users)
  provisioner "local-exec"{
      command ="aws ec2 stop-instances --instance-ids ${aws_instance.ec2[count.index].id} --profile ${var.profile} --region ${var.region} --force >> ec2stop.txt" 
  }
}