variable "region" {
  description = "Default AWS region for S3 and most resources."
  type        = string
  default     = "ca-central-1"
}

variable "us_region" {
  description = "AWS region for CloudFront and ACM (must be us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  type    = string
  default = ""
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  alias   = "us"
  region  = var.us_region
  profile = var.profile
}
