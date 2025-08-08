locals {
  policy_arns = [
    aws_iam_policy.bucket_policy.arn,
    aws_iam_policy.glue_access_policy.arn,
  ]
}

data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    sid = "GlueAssumeRole"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "glue_role"
  description        = "role description" # TODO: fill me in
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count      = length(local.policy_arns)
  role       = aws_iam_role.glue_role.name
  policy_arn = local.policy_arns[count.index]
}
