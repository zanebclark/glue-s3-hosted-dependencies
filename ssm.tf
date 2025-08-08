resource "aws_ssm_parameter" "additional_python_modules" {
  name        = "/glue-s3-hosted-dependencies/additional-python-modules"
  description = "A list of whl file S3 URLs to be used for the Glue --additional-python-modules job parameter"
  type        = "StringList"
  # We're just creating the parameter here so that it exists and we can reference it when deploying the Glue job.
  # The value of the parameter will exclusively be controlled by the script run in the Dockerfile
  insecure_value = "initial,placeholder"
  overwrite      = false

  # Terraform won't control the value, but will reference it
  lifecycle {
    ignore_changes = [insecure_value]
  }
}
