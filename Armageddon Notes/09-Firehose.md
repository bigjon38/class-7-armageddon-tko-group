---
title: 09-firehose
name: 09-firehose
description: Conditional WAF logging pipeline using Kinesis Data Firehose delivering logs to S3 with IAM role and scoped permissions.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - waf
  - firehose
  - s3
  - iam
  - logging
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

# 09-firehose

---

![[media/image1.png]]

# WAF Firehose S3 Destination

## S3 Bucket (Conditional)

- **provider = aws** → Uses your *default* AWS provider (likely Tokyo).
- `count = var.waf_log_destination == "firehose" ? 1 : 0`

### Behavior

|waf_log_destination|Bucket Created?|
|---|---|
|firehose|✅ Yes (1 bucket)|
|anything else|❌ No (0 buckets)|

---

## force_destroy = True

Terraform will delete the bucket even if it has objects inside.

- ⚠ Dangerous in production
- Useful for labs and teardown testing

---

## Bucket Naming Strategy

Bucket name includes:

- `project_name`
- Region hint (`apne1`)
- AWS `account_id`

Because S3 bucket names are **globally unique**.

### Example Result

```text
armageddon-waf-firehose-dest-apne1-123456789012
```

---

![[media/image2.png]]

# IAM Role for Firehose

Creates an IAM **Role**.

### Trust Policy (Assume Role)

Allows:

```text
firehose.amazonaws.com
```

To assume the role via:

```text
sts:AssumeRole
```

### Result

Firehose now has an identity it can use to call AWS APIs (like writing to S3).

---

![[media/image3.png]]

# Inline Policy – S3 Permissions

Attached directly to the Firehose role.

Because `count` was used:

```text
role = aws_iam_role.firehose_role[0].id
```

---

## Allowed S3 Actions

Minimum required permissions:

### Object-Level

- `s3:PutObject`
- `s3:AbortMultipartUpload`
- Multipart-related permissions

### Bucket-Level

- `s3:ListBucket`
- `s3:GetBucketLocation`

---

## Resource Scope

Includes:

- Bucket ARN (for bucket-level actions)
- Bucket objects ARN (`bucket/*`) for object writes

### Result

Firehose can write log files into the bucket, but only that bucket.

---

![[media/image4.png]]

# Firehose Delivery Stream

Creates a delivery stream:

```text
aws-waf-logs-armageddon-apne1-firehose01
```

Destination:

```text
extended_s3
```

---

## extended_s3_configuration

### role_arn

Firehose uses the IAM role created earlier.

### bucket_arn

Destination S3 bucket.

### Prefix = "waf-logs/"

All delivered objects go under:

```text
s3://<bucket>/waf-logs/
```

---

# Full WAF Logging Flow

```text
WAF
   ↓
Kinesis Data Firehose
   ↓ (Assumes IAM Role)
S3 Bucket
   ↓
waf-logs/ prefix
```

---

# Design Patterns Used

|Pattern|Purpose|
|---|---|
|Conditional creation (count)|Feature toggle|
|Service trust policy|Allow AWS service to assume role|
|Least privilege IAM|Minimal S3 permissions|
|Prefixed log storage|Organized object structure|
|force_destroy (lab mode)|Easy teardown|

---

# Mental Model

- If WAF log destination = firehose → build full pipeline
- Firehose assumes role
- Role can write only to that bucket
- Logs land under `waf-logs/`
- Entire setup can be toggled on/off via variable
