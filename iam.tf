resource "aws_iam_user" "uploader" {
  name = var.uploader_user_name
}

resource "aws_iam_user_policy" "uploader_policy" {
  name = "uploader-policy"
  user = aws_iam_user.uploader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:GetBucketPublicAccessBlock"
        ]
        Resource = [aws_s3_bucket.uploads.arn]
      },
      {
        Sid    = "AllowS3ObjectRW"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = ["${aws_s3_bucket.uploads.arn}/*"]
      }
      ,
      {
        Sid    = "AllowS3ListAllBucketsForDiscovery"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_access_key" "uploader_key" {
  user = aws_iam_user.uploader.name
}
