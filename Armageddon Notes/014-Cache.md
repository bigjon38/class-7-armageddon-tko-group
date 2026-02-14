---
title: 014-cache
name: 014-cache
description: CloudFront cache policies, origin request policies, and response header policies for static assets and API traffic.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - cloudfront
  - cache-policy
  - origin-request-policy
  - response-headers
  - cdn
type: notes
status: active
disabled rules:
---


## Links

[00-Armageddon-Notes-Main](00-Armageddon-Notes-Main.md)

---

# 014-cache

---

![](media/image1.png)

# Static Cache Policy

## What It Is

A **Cache Policy** tells CloudFront:

- How to build the **cache key**
- How long to cache objects

---

## Provider

```text
provider = aws.use1
```

CloudFront control plane resources are managed in **us-east-1**.

---

## TTL Settings

- `default_ttl = 86400` (1 day)
- `max_ttl = 31536000` (1 year)
- `min_ttl = 0`

If origin does not specify caching headers:

- Default cache = 1 day
- Can cache up to 1 year
- Can also not cache if headers require

---

## Cache Key Configuration

### Cookies

```text
cookie_behavior = "none"
```

- Cookies not forwarded
- Not part of cache key

Good for static assets.

---

### Query Strings

```text
query_string_behavior = "none"
```

- Ignored
- Not forwarded

⚠ If using:

```text
app.js?v=123
```

Ignoring query strings could break versioning.

---

### Headers

```text
header_behavior = "none"
```

- No headers forwarded
- No headers in cache key

Reduces cache fragmentation.

---

## Compression Support

```text
enable_accept_encoding_gzip = true
enable_accept_encoding_brotli = true
```

CloudFront caches separate compressed variants.

---

## Bottom Line

Efficient caching for:

```text
/static/*
```

Very high cache hit ratio.

---

![](media/image2.png)

# No-Cache Policy (API)

## Purpose

Disable CDN caching.

---

## TTL Settings

- `default_ttl = 0`
- `max_ttl = 0`
- `min_ttl = 0`

CloudFront treats everything as immediately stale.

---

## Forwarding Behavior

Cookies, headers, and query strings set to `"none"` in cache policy.

⚠ Actual forwarding is controlled by **Origin Request Policy**.

---

## Bottom Line

Use on:

```text
/api/*
```

Ensures API responses are not cached.

---

![](media/image3.png)

# Origin Request Policy (API)

## What It Is

Controls what CloudFront forwards to origin:

- On cache miss
- Or always (if caching disabled)

---

## Cookies

```text
cookie_behavior = "all"
```

Forward all cookies.

Needed for:

- Authenticated APIs
- Session handling

---

## Query Strings

```text
query_string_behavior = "all"
```

Forward all query parameters.

Required for:

- Pagination
- Filters
- Search queries

---

## Headers (Whitelist)

```text
header_behavior = "whitelist"
```

Forward only selected headers:

- `Content-Type`
- `Origin`
- `Host`

---

### Why These?

|Header|Reason|
|---|---|
|Content-Type|Required for POST/PUT|
|Origin|Required for CORS logic|
|Host|Required for host-based routing|

---

## Bottom Line

Even with caching disabled, the origin must receive necessary request context.

---

![](media/image4.png)

# Origin Request Policy (Static)

For static assets:

- No cookies
- No query strings
- No headers

Maximizes cache hit ratio.

---

![](media/image5.png)

# Response Headers Policy (Static)

## What It Does

Allows CloudFront to add/modify headers in responses to viewers.

---

## Cache-Control Header

Adds:

```text
Cache-Control: public, max-age=86400, immutable
```

### Meaning

- `public` → Browsers/shared caches can cache
- `max-age=86400` → Cache 1 day
- `immutable` → Do not revalidate

Best used with versioned filenames:

```text
app.abc123.js
```

---

## Override = True

CloudFront replaces any `Cache-Control` header from origin.

---

# Behavior Summary

|Path|Cache Policy|Origin Request Policy|Result|
|---|---|---|---|
|/static/*|Long TTL|Minimal forwarding|High CDN cache hit|
|/api/*|TTL = 0|Forward all context|No CDN caching|
|Default|Disabled caching|Controlled forwarding|Dynamic behavior|

---

# Architecture Pattern

```text
Viewer
   ↓
CloudFront
   ↓
Path-based behavior
   ↓
Cache Policy + ORP
   ↓
Origin (ALB)
```

---

# Mental Model

- Cache Policy → Controls cache key + TTL
- Origin Request Policy → Controls what origin sees
- Response Headers Policy → Controls what viewer sees
- Static = aggressive caching
- API = no caching, full request context
