# ============================================================
# Lab 2 – CloudFront Cache Policies
# Purpose: Control how CloudFront caches different content
# ============================================================

# Static assets: cache aggressively (images, CSS, JS)
resource "aws_cloudfront_cache_policy" "static_cache01" {
  name        = "kamau-static-cache01"
  comment     = "Aggressive cache for /static/* – 1 day default, 1 year max"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Origin request policy for static assets
resource "aws_cloudfront_origin_request_policy" "static_orp01" {
  name    = "kamau-static-orp01"
  comment = "Origin request policy for static assets"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}
