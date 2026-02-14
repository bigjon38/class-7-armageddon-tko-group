---
title: 08-alb-access-logs-s3
name: 08-alb-access-logs-s3
description: Conditional S3 bucket creation for ALB access logs with public access blocking, TLS enforcement, object ownership configuration, and scoped log delivery permissions.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - s3
  - alb
  - logging
  - iam-policy
  - security
type: notes
status: active
disabled rules:
---


## Links

[00-Armageddon-Notes-Main](00-Armageddon-Notes-Main.md)

---

# 08-alb-access-logs-s3

---

![](media/image1.png)

# AWS Caller Identity (Data Source)

This **does not create anything**.

It queries AWS for your current identity information:

- `account_id`
- `arn`
- `user_id`

### Why This Matters

You use `account_id` later to:

- Make the S3 bucket name globally unique
- Scope the bucket policy to your account’s ALB log path

---

![](media/image2.png)

# Conditional S3 Bucket Creation

```text
count = var.enable_alb_access_logs ? 1 : 0
```

### Behavior

|enable_alb_access_logs|Result|
|---|---|
|true|Create 1 bucket|
|false|Create 0 buckets|

Because `count` is used:

```text
aws_s3_bucket.armageddon_alb_logs_bucket[0]
```

Refers to the one bucket (when enabled).

---

## Why Include account_id in the Bucket Name?

S3 bucket names are **globally unique**.

Including your AWS account ID prevents naming collisions.

---

![](media/image3.png)

# Block Public Access (S3 Guardrails)

This enables S3 public access blocking:

- `block_public_acls`
- `ignore_public_acls`
- `block_public_policy`
- `restrict_public_buckets`

### Net Effect

The bucket **cannot become public**.

|Setting|Protection|
|---|---|
|block_public_acls|Prevents public ACL assignment|
|ignore_public_acls|Ignores existing public ACLs|
|block_public_policy|Prevents public bucket policies|
|restrict_public_buckets|Extra enforcement safeguard|

---

![](media/image4.png)

# Object Ownership

Configures how object ownership works when AWS services write logs.

Setting:

```text
BucketOwnerPreferred
```

### Meaning

If uploader sets correct ACL:

- **Bucket owner becomes object owner**

Prevents "I can't read my own logs" issues.

---

![](media/image5.png)

# S3 Bucket Policy

Attaches an IAM-style policy to the bucket.

---

![](media/image6.png)

## Enforce HTTPS (TLS Only)

Denies **any S3 action** if the request is not using HTTPS.

### Security Pattern

Prevents accidental plaintext access.

Condition example:

```text
"aws:SecureTransport": "false"
```

→ Deny request

---

![](media/image7.png)

# Allow ALB Log Delivery

Allows the **ALB log delivery service principal** to:

```text
s3:PutObject
```

Only into the expected log folder path.

---

## Log Path Logic

Depends on `alb_access_logs_prefix`.

### If Prefix is Set (example: alb-logs)

Logs go under:

```text
s3://bucket/alb-logs/AWSLogs/<account_id>/
```

### If Prefix is Empty

Logs go under:

```text
s3://bucket/AWSLogs/<account_id>/
```

---

# Full Logging Flow

```text
ALB
   ↓
S3 Bucket (Private)
   ↓
TLS Enforced
   ↓
Scoped Write Permission
```

---

# Design Patterns Used

|Pattern|Purpose|
|---|---|
|Data source identity|Account-aware naming|
|Conditional resource creation|Feature toggle|
|Public access blocking|Prevent data exposure|
|TLS enforcement policy|Secure transport only|
|Scoped service principal access|Least privilege|
|Object ownership config|Prevent log access issues|

---

# Mental Model

- Bucket only exists if logging enabled
- Bucket can never be public
- Only ALB can write logs
- Logs restricted to your account path
- All access must use HTTPS
