---
title: 013-route53-records
name: 013-route53-records
description: Route53 alias records for apex, subdomain, and origin mapping CloudFront to ALB with clean origin abstraction and origin cloaking support.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - route53
  - dns
  - cloudfront
  - alb
type: notes
status: active
disabled rules:
---

### Configuration

[Linter Rules](Linter-Rules.md)<br>
[Disabling Linter Rules](Obsidian-Linter-Disabling-Rules)<br>
[Markdown Cheatsheet](Markdown-Cheat-Sheet)

## Links

[00-Armageddon-Notes-Main]

---

# 013-route53-records

---

![[media/image1.png]]

# Apex Domain → CloudFront

## Route53 A Record (Alias)

- **zone_id** → Hosted zone where record is created<br>
    (example: hosted zone for `librashift.com`)
    
- `name = var.domain_name`<br>
    This is your **apex/root domain**:

    ```text
    librashift.com
    ```

- `type = "A"`<br>
    A-record (but using alias, so no static IP stored)

---

![[media/image2.png]]

## Alias Target – CloudFront

- `alias.name` → CloudFront DNS name<br>
    Example:

    ```text
    d123abcd.cloudfront.net
    ```

- `alias.zone_id` → CloudFront hosted zone ID<br>
    (Provided automatically by AWS)
    
- `evaluate_target_health = false`<br>
    Route53 does not perform health check evaluation for this alias.

---

## Result

```text
yourdomain.com → CloudFront
```

---

![[media/image3.png]]

# Subdomain → CloudFront

Same hosted zone.

- `name = var.app_subdomain`

Usually:

- `app` → becomes `app.yourdomain.com`<br>
    **or**
    
- `app.yourdomain.com` (FQDN)

Either works if consistent.

---

![[media/image4.png]]

## Result

```text
app.yourdomain.com → CloudFront
```

---

## Why Both Apex and App Point to Same Distribution?

- Same site served on both domains
- Or CloudFront behaviors handle routing differences
- Centralized CDN layer

---

# Origin Record

---

![[media/image5.png]]

Creates:

```text
origin.yourdomain.com
```

Explicit DNS entry.

---

![[media/image6.png]]

## Origin → ALB Alias

- `aws_lb.armageddon_alb.dns_name`<br>
    Example:

    ```text
    my-alb-123456.us-east-1.elb.amazonaws.com
    ```

- `aws_lb.armageddon_alb.zone_id`<br>
    Required for Route53 alias to ALB.

---

## Result

```text
origin.yourdomain.com → ALB
```

---

# Why Use origin.yourdomain.com?

Instead of pointing CloudFront directly at:

```text
my-alb-123456.us-east-1.elb.amazonaws.com
```

You gain flexibility:

---

## Benefits

### 1. Cleaner CloudFront Config

CloudFront origin:

```text
origin.yourdomain.com
```

Instead of raw ELB hostname.

---

### 2. Easier ALB Rotation

If ALB changes:

- Update Route53 record only
- No need to modify CloudFront origin config

---

### 3. Origin Cloaking

You can:

- Lock ALB SG to allow only CloudFront
- Require secret origin header
- Prevent direct-to-ALB access

---

# Full DNS Flow

```text
User
   ↓
yourdomain.com / app.yourdomain.com
   ↓
CloudFront
   ↓
origin.yourdomain.com
   ↓
Application Load Balancer
```

---

# Architecture Pattern

|Record|Points To|Purpose|
|---|---|---|
|Apex A Alias|CloudFront|Primary domain|
|App Subdomain|CloudFront|App endpoint|
|origin Subdomain|ALB|Internal origin abstraction|

---

# Mental Model

- Apex + app → CDN layer
- CDN → origin.yourdomain.com
- origin → ALB
- ALB locked down to CloudFront only
- DNS abstraction = operational flexibility
