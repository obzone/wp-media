variable "bucket_name" {
  description = "S3 bucket name to store WordPress uploads. Leave empty to let Terraform generate a unique name with prefix 'wp-uploads-'."
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "If true, allows Terraform to delete non-empty bucket. Use with caution."
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_comment" {
  description = "Comment/description for the CloudFront distribution"
  type        = string
  default     = "CloudFront for WordPress uploads"
}

variable "enable_logging" {
  description = "Enable S3 access logging for the bucket."
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Optional bucket to send access logs to. If empty and logging enabled, a logging bucket will be created."
  type        = string
  default     = ""
}

variable "uploader_user_name" {
  description = "IAM user name that will be created for uploads."
  type        = string
  default     = "wp-uploader"
}
variable "certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 for the custom domain. Leave empty to use the default CloudFront certificate (*.cloudfront.net)."
  type        = string
  default     = ""
}

variable "backend_origin_domain" {
  description = "Origin domain name for backend server (e.g. www.mixology.cloud). CloudFront will forward dynamic requests to this origin."
  type        = string
  default     = ""
}

variable "s3_alias" {
  description = "Alias (CNAME) for the S3 CloudFront distribution, e.g. s3.www.mixology.cloud"
  type        = string
  default     = ""
}

variable "wp_alias" {
  description = "Alias (CNAME) for the backend CloudFront distribution, e.g. www.www.mixology.cloud"
  type        = string
  default     = ""
}
