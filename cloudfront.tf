resource "aws_cloudfront_origin_access_control" "oac" {
  provider                          = aws.us
  name                              = "wp-uploads-oac"
  description                       = "OAC for wp uploads (sigv4)"
  origin_access_control_origin_type = "s3"
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
}
resource "aws_cloudfront_distribution" "cdn_s3" {
  provider        = aws.us
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront for S3 uploads (s3 alias)"

  lifecycle {
    precondition {
      condition     = var.s3_alias == "" || var.certificate_arn != ""
      error_message = "When s3_alias is set, you must provide certificate_arn (ACM cert in us-east-1) for CloudFront."
    }
  }

  price_class = var.cloudfront_price_class
  aliases     = var.s3_alias == "" ? [] : [var.s3_alias]

  origin {
    domain_name              = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id                = "s3-uploads-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-uploads-origin"
    compress         = true

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn != "" ? var.certificate_arn : null
    ssl_support_method             = var.certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != "" ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.certificate_arn == "" ? true : false
  }

  depends_on = [aws_s3_bucket.uploads]
}

resource "aws_cloudfront_distribution" "cdn_wp" {
  logging_config {
    bucket          = var.logging_bucket != "" ? var.logging_bucket : aws_s3_bucket.cloudfront_logs.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront/wp/"
  }
  provider        = aws.us
  enabled         = false
  is_ipv6_enabled = true
  comment         = "CloudFront for backend (WordPress + WooCommerce)"

  lifecycle {
    precondition {
      condition     = var.wp_alias == "" || var.certificate_arn != ""
      error_message = "When wp_alias is set, you must provide certificate_arn (ACM cert in us-east-1) for CloudFront."
    }
  }

  price_class = var.cloudfront_price_class
  aliases     = var.wp_alias == "" ? [] : [var.wp_alias]

  origin {
    domain_name = var.backend_origin_domain
    origin_id   = "backend-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Cache static WordPress assets aggressively while keeping origin the same.
  ordered_cache_behavior {
    path_pattern     = "/wp-content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "backend-origin"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = [
        "Origin",
        "Host",
        "CloudFront-Forwarded-Proto",
        "X-Forwarded-Proto",
      ]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 300
    default_ttl            = 86400
    max_ttl                = 604800
  }

  ordered_cache_behavior {
    path_pattern     = "/wp-includes/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "backend-origin"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = [
        "Origin",
        "Host",
        "CloudFront-Forwarded-Proto",
        "X-Forwarded-Proto",
      ]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 300
    default_ttl            = 86400
    max_ttl                = 604800
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "backend-origin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = [
        "Authorization",
        "Origin",
        "Host",
        "CloudFront-Forwarded-Proto",
        "X-Forwarded-Proto",
      ]
    }

    viewer_protocol_policy = "redirect-to-https"

    # WooCommerce is highly personalized (cart/session/auth). Keep default behavior uncacheable.
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn != "" ? var.certificate_arn : null
    ssl_support_method             = var.certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != "" ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.certificate_arn == "" ? true : false
  }

}
