variable "profile" {
  default     = "personal"
  description = "AWS SSO profile"
  type        = string
}

variable "environment" {
  description = "The environment abbreviation used in the naming scheme of many objects"
  type        = string
}

variable "region" {
  default     = "us-west-1"
  description = "AWS Deployment Region"
  type        = string
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}
