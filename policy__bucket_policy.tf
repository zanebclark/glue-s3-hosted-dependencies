data "aws_iam_policy_document" "bucket_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = ["${aws_s3_bucket.glue_scripts.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetBucketAcl",
    ]
    resources = [aws_s3_bucket.glue_scripts.arn]
  }
}

resource "aws_iam_policy" "bucket_policy" {
  name        = "${var.environment}-bucket-policy"
  description = "IAM policy for S3 buckets"
  policy      = data.aws_iam_policy_document.bucket_policy_document.json
  lifecycle {
    create_before_destroy = false
  }
}
