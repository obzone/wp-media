# WordPress uploads on S3 with CloudFront (Terraform)

This Terraform config creates an S3 bucket to store WordPress uploads, a CloudFront distribution in front of the bucket (using an Origin Access Identity), and an IAM user with credentials for uploading files.

Files added:
- `versions.tf` – Terraform and provider constraints
- `provider.tf` – AWS provider configuration
- `variables.tf` – configurable inputs
- `s3.tf` – S3 bucket, public access block, bucket policy
- `cloudfront.tf` – CloudFront distribution and OAI
- `iam.tf` – IAM user and access key for uploads
- `outputs.tf` – outputs for bucket, CloudFront domain, and keys

Quick start

1. Initialize Terraform

```bash
terraform init
```

2. Review the plan

```bash
terraform plan -out plan.tfplan
```

3. Apply

```bash
terraform apply "plan.tfplan"
```

Notes and security
- The `uploader` access key and secret are stored in the Terraform state; keep the state secure.
- The CloudFront distribution uses the default CloudFront certificate (`*.cloudfront.net`). For a custom domain, replace the `viewer_certificate` block and add the domain/ACM cert.
- The bucket policy restricts access to requests coming from the created CloudFront distribution.

Custom domain & SSL
- To serve using a custom domain (for example `s3.mixology.cloud`) set the `custom_domain` variable and supply an ACM certificate ARN in `certificate_arn`.
 - To serve using custom domains set either `custom_domains` (list) or the per-distribution aliases `s3_alias` / `wp_alias`, and supply an ACM certificate ARN in `certificate_arn` that covers the names.

IMPORTANT: CloudFront requires the ACM certificate to be issued in the `us-east-1` (N. Virginia) region. Create or request the certificate in `us-east-1` and provide its ARN via `certificate_arn`.

Example `terraform.tfvars` entries:

```hcl
# multiple via list
#custom_domains = ["s3.mixology.cloud", "www.mixology.cloud"]

# or per-distribution
#s3_alias = "s3.www.mixology.cloud"
#wp_alias = "www.www.mixology.cloud"
#certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

If you prefer Terraform to request and validate a certificate automatically, I can add `aws_acm_certificate` and DNS validation via Route53 (requires you to manage the DNS zone in Route53). Currently the module expects you to supply a pre-created certificate ARN.

Multiple distributions
- This configuration can create two separate CloudFront distributions in the same `cloudfront.tf` file: one for the S3 bucket (set `s3_alias`) and one for the backend WP site (set `wp_alias`). Example:

```hcl
# s3 distribution CNAME
#s3_alias = "s3.www.mixology.cloud"

# wp distribution CNAME
#wp_alias = "www.www.mixology.cloud"

# certificate ARN covering both names
#certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Make sure the ACM certificate covers both hostnames (or use separate certificates and supply per-distribution ARNs — I can add that if needed).
