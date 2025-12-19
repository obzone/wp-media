resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "${local.bucket_name}-cf-logs"
  force_destroy = true

  tags = {
    Name = "cloudfront-logs"
    Env  = "terraform"
  }
}

# S3 ownership controls are separate resources in aws provider v6+
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# Keep bucket private; ensure ownership controls are applied first
resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_logs
  ]
}

# Recommended: block all public access for log bucket
resource "aws_s3_bucket_public_access_block" "cloudfront_logs_block" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Recommended: enable default encryption for log bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_encryption" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  bucket_name = var.bucket_name != "" ? var.bucket_name : "wp-uploads-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "uploads" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = "wp-uploads"
    Env  = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "uploads_versioning" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "uploads_block" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "uploads_policy" {
  bucket = aws_s3_bucket.uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServiceGetObject"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.uploads.arn}/*"]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn_s3.id}"
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.cdn_s3]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads_encryption" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Move objects to S3 Intelligent-Tiering to reduce storage cost for infrequently accessed images.
# Note: new uploads may still start as STANDARD; this lifecycle rule transitions them automatically.
resource "aws_s3_bucket_lifecycle_configuration" "uploads_lifecycle" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "to-intelligent-tiering"
    status = "Enabled"

    # Empty filter == apply to all objects in the bucket
    filter {}

    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  depends_on = [aws_s3_bucket.uploads]
}

# Optional: enable Intelligent-Tiering archive tiers.
# If you don't want automatic archive/deep-archive, remove this resource.
resource "aws_s3_bucket_intelligent_tiering_configuration" "uploads_it" {
  bucket = aws_s3_bucket.uploads.id
  name   = "uploads-it"
  status = "Enabled"

  filter {
    prefix = ""
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

data "aws_caller_identity" "current" {}
