resource "aws_s3_bucket" "glue_scripts" {
  bucket_prefix = "glue-s3-hosted-dep-${var.environment}-scripts"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning_disabled" {
  bucket = aws_s3_bucket.glue_scripts.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256" {
  bucket = aws_s3_bucket.glue_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
