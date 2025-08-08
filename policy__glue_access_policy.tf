data "aws_iam_policy_document" "glue_access_policy_document" {
  version = "2012-10-17"
  statement {
    sid = "ActionsThatDoNotRequireResources"
    actions = [
      "s3:ListAllMyBuckets",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "MoreActionsThatDoNotRequireResources"
    effect = "Allow"
    actions = [
      "glue:DescribeConnectionType",
      "glue:ListConnectionTypes",
      "glue:ListJobs",
      "glue:ResetJobBookmark"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:GetEntityRecords",
      "glue:ListEntities",
      "glue:RefreshOAuth2Tokens"
    ]
    resources = concat(
      [for conn in aws_glue_connection.default : conn.arn],
      ["arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"]
    )
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:BatchGetJobs",
      "glue:BatchStopJobRun",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:GetJobUpgradeAnalysis",
      "glue:GetJobs",
      "glue:GetTags",
      "glue:ListJobUpgradeAnalyses",
      "glue:StartJobRun",
      "glue:StartJobUpgradeAnalysis",
      "glue:StopJobUpgradeAnalysis",
      "glue:TagResource",
      "glue:UntagResource",
      "glue:UpdateJob",
      "glue:UpgradeJob"
    ]
    resources = [aws_glue_job.this.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DeleteLogDelivery",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeResourcePolicies",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:PutRetentionPolicy",
      "logs:UpdateLogDelivery",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*:/aws-glue/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
  }
}

resource "aws_iam_policy" "glue_access_policy" {
  name        = "${var.environment}-policy-glue-access-policy"
  description = "Glue IAM policy, for glue connections and service"
  policy      = data.aws_iam_policy_document.glue_access_policy_document.json
}
