output "s3_bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}

output "cloudfront_s3_domain" {
  value = aws_cloudfront_distribution.cdn_s3.domain_name
}

output "cloudfront_wp_domain" {
  value = aws_cloudfront_distribution.cdn_wp.domain_name
}

output "uploader_access_key_id" {
  value = aws_iam_access_key.uploader_key.id
}

output "uploader_secret_access_key" {
  value     = aws_iam_access_key.uploader_key.secret
  sensitive = true
}
