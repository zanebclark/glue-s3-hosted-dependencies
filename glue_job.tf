data "aws_ssm_parameter" "additional_python_modules" {
  name = aws_ssm_parameter.additional_python_modules.name
}

locals {
  glue_scripts_dir = "./glue_scripts"
  script_filepath  = "${local.glue_scripts_dir}/hello_world.py"
  script_filename  = basename(local.script_filepath)
}

resource "aws_s3_object" "this" {
  bucket      = aws_s3_bucket.glue_scripts.bucket
  key         = local.script_filepath
  source      = local.script_filepath
  source_hash = filemd5(local.script_filepath)
  override_provider {
    default_tags {
      tags = {}
    }
  }
}

resource "aws_glue_job" "this" {
  name            = "aws-use1-${var.environment}-hello-world"
  role_arn        = aws_iam_role.glue_role.arn
  glue_version    = "4.0"
  timeout         = 240
  max_retries     = 0
  connections     = values(aws_glue_connection.default)[*].name
  execution_class = "STANDARD"
  execution_property {
    max_concurrent_runs = 4
  }
  worker_type       = "G.1X"
  number_of_workers = 2
  #noinspection TfUnknownProperty
  job_run_queuing_enabled = false

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/glue_scripts/${local.script_filename}"
    python_version  = 3
  }

  default_arguments = {
    "--env_name"                         = var.environment
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--argument_name"                    = "argument"
    "--disable-proxy-v2"                 = "true"
    "--additional-python-modules"        = data.aws_ssm_parameter.additional_python_modules.value
  }
}
