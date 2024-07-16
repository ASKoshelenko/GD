      # command = join(" ", [
      #   "../UpdateDB.py ${var.profile}",
      #   "${var.scenario-name}",
      #   "${var.dbName}",
      #   "\"${join(" ", local.emails)}\"",
      #   "\"${join(" ", aws_iam_access_key.scenario4_1_user.*.id)}\"",
      #   "\"${join(" ", aws_iam_access_key.scenario4_1_user.*.secret)}\"",
      #   "\"${join(" ", aws_iam_user.scenario4_1_user.*.name)}\" >> dbupdate.txt"
      # ])