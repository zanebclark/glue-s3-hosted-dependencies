terraform {
  required_version = "~>1.11.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to avoid unexpected problems
      version = "6.8.0"
    }
  }
  # backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {}
  }
}
