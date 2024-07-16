
            # command = join(" ", [
      #   "../UpdateDB.py ${var.profile}",
      #   "${var.scenario-name}",
      #   "${var.dbName}",
      #   "\"${join(" ", local.emails)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.id)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.secret)}\"",
      #   "\"${join(" ", aws_iam_user.user.*.name)}\"",
      #   "\"${join(" ", aws_instance.ec2.*.id)}\"",
      #   "\"${join(" ", aws_iam_policy.user-termination-policy.*.arn)}\" >> dbupdate.txt"
      # ])