#AWS Account Id
data "aws_caller_identity" "aws-account-id" {
  
}

data "aws_iam_policy_document" "v1" {
  count = length(local.users)
  statement {
    effect = "Allow"
    sid = "Terraform0"
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Deny"
    sid = "Terraform1"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::prepared-user-templates-hackathon/*",
      "arn:aws:s3:::prepared-user-templates-hackathon"
    ]
  }

  statement {
    effect = "Allow"
    sid = "IAMPrivilegeEscalationByRollback"
    actions = [
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/policy_${var.scenario-name}_${local.users[count.index].userid}"]
  }

  statement {
    effect = "Deny"
    sid = "Terraform3"
    actions = [
      "iam:ListUsers"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "v2" {
  count = length(local.users)
  statement {
    effect = "Deny"
    not_actions = ["iam:SetDefaultPolicyVersion"]
    sid = "Terraform0"
    resources = ["*"]
    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"
      values = [
          "192.0.2.0/24",
          "203.0.113.0/24",
          "178.0.15.35/24"
        ]
      }
    condition{
      test = "DateLessThan"
      variable = "aws:CurrentTime"
      values = [ "2030-04-01T23:59:59Z" ]
    }
  }

  statement {
    effect = "Allow"
    sid = "IAMPrivilegeEscalationByRollback"
    actions = [
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/policy_${var.scenario-name}_${local.users[count.index].userid}"]
  }
}

data "aws_iam_policy_document" "v3" {
  count = length(local.users)
  statement {
    effect = "Allow"
    sid = "Terraform0"
    actions = ["*"]
    resources = ["arn:aws:s3:::sc-super-secured-bucket123/*"]
  }

  statement {
    effect = "Allow"
    sid = "IAMPrivilegeEscalationByRollback"
    actions = [
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/policy_${var.scenario-name}_${local.users[count.index].userid}"]
  }
}

data "aws_iam_policy_document" "v4" {
  count = length(local.users)
  statement {
    effect = "Allow"
    sid = "Terraform0"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = ["*"]
    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"
      values = [ "128.0.0.2/24" ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:ChangePassword",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
    condition {
      test = "DateGreaterThan"
      variable = "aws:CurrentTime"
      values = [ "2023-03-07T00:00:00Z" ]
    }
    condition {
      test = "DateLessThan"
      variable = "aws:CurrentTime"
      values = [ "2023-05-10T23:59:59Z" ]
    }
  }

  statement {
    effect = "Allow"
    sid = "IAMPrivilegeEscalationByRollback"
    actions = [
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/policy_${var.scenario-name}_${local.users[count.index].userid}"]
  }
}

data "aws_iam_policy_document" "v5" {
  count = length(local.users)
  statement {
    effect = "Allow"
    sid = "Terraform1"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    sid = "Terraform2"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::gameday-dashboard/*",
      "arn:aws:s3:::gameday-dashboard"
    ]
  }
  statement {
    effect = "Deny"
    sid = "Terraform3"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::prepared-user-templates-hackathon/*",
      "arn:aws:s3:::prepared-user-templates-hackathon"
    ]
  }

  statement {
    effect = "Allow"
    sid = "IAMPrivilegeEscalationByRollback"
    actions = [
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/policy_${var.scenario-name}_${local.users[count.index].userid}"]
  }
}
