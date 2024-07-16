      # command = join(" " ,[
      #   "echo  \"${join(", ", local.emails)}\">> emails.txt\n",
      #   "echo  \"${join(", ", aws_iam_access_key.user-key.*.id)}\" >> keys.txt"
      #   ])

      # command = join(" ", [
      #   "../UpdateDBv2.py ${var.profile}",
      #   "${var.scenario-name}",
      #   "${var.dbName}",
      #   "\"${join(" ", local.emails)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.id)}\"",
      #   "\"${join(" ", aws_iam_access_key.user-key.*.secret)}\"",
      #   "\"${join(" ", aws_iam_user.user.*.name)}\" >> dbupdate.txt"
      # ])