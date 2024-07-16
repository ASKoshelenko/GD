      # command = join(" ", [
      #   "../UpdateDB.py ${var.profile}",
      #   "${var.scenario-name}",
      #   "${var.dbName}",
      #   "\"${join(" ", local.emails)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.id)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.secret)}\"",
      #   "\"${join(" ", aws_iam_user.user.*.name)}\"",
      #   "${aws_instance.ec2.public_ip}",
      #   "\"${join(" ", aws_lambda_function.Sc2FinCheck.*.function_name)}\"",
      #   "\"${join(" ", local.codes)}\" >> dbupdate.txt"
      # ])