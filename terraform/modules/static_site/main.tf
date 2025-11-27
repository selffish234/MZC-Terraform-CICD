terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.virginia ]
    }
  }
}
resource "aws_s3_bucket" "this" {
  bucket        = var.full_domain_name
  force_destroy = true
  tags = { Name = "${var.prefix}-frontend-bucket" }
}
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "cloudfront.amazonaws.com" },
      Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.this.arn}/*",
      Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.this.arn } }
    }]
  })
}
data "aws_route53_zone" "this" {
  name = var.domain_name
}
resource "aws_acm_certificate" "frontend" {
  provider          = aws.virginia
  domain_name       = var.full_domain_name
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.prefix}-frontend-cert" }
}
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => dvo
  }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.this.zone_id
}
resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "S3-${var.prefix}-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.full_domain_name]
  price_class         = "PriceClass_100"
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.prefix}-frontend"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.frontend.certificate_arn
    ssl_support_method  = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = { Name = "${var.prefix}-cloudfront" }
}
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.full_domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
