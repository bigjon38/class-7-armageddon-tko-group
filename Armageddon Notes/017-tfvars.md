---
title: 017-tfvars
name: 017-tfvars
description: Terraform variable configuration controlling Route53 management mode, hosted zone usage, and WAF logging destination via Firehose.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - tfvars
  - route53
  - waf
  - firehose
  - configuration
type: notes
status: active
disabled rules:
---

### Configuration

[Linter Rules](Linter-Rules.md)<br>
[Disabling Linter Rules](Obsidian-Linter-Disabling-Rules)<br>
[Markdown Cheatsheet](Markdown-Cheat-Sheet)

# 017-tfvars

---

![[media/image1.png]]

# Route53 Management Mode

## manage_route53_in_terraform = False

This means:

> "Do NOT create or manage the Route 53 Hosted Zone with Terraform."

---

## What Happens in Code

Typically:

```hcl
count = var.manage_route53_in_terraform ? 1 : 0
```

So when set to `false`:

- `aws_route53_zone` resources are skipped
- Terraform will NOT create a hosted zone
- Terraform will NOT modify existing hosted zone configuration

---

## Practical Meaning

- Route 53 hosted zone already exists
- Terraform only creates DNS records
- Hosted zone lifecycle is managed outside Terraform

---

# Hosted Zone ID

## route53_hosted_zone_id = "hosted_zone"

This provides the **Hosted Zone ID** where DNS records will be created.

When:

```text
manage_route53_in_terraform = false
```

Terraform needs this ID to know where to create records like:

- Apex A record → CloudFront
- `app.yourdomain.com` → CloudFront
- `origin.yourdomain.com` → ALB

---

## Mental Model

```text
Hosted Zone = DNS container
Records = Entries inside container
```

Terraform is only managing records, not the container itself.

---

# WAF Log Destination

## waf_log_destination = "firehose"

This is a feature toggle controlling:

> Where WAF logs should go.

---

## When Set to "firehose"

Terraform will typically:

1. Create a **Kinesis Data Firehose delivery stream**
2. Create an **S3 bucket** for log storage
3. Create an **IAM role + policy** for Firehose
4. Configure:

    ```text
    aws_wafv2_web_acl_logging_configuration
    ```

    To send logs to Firehose

---

## Resulting Flow

```text
WAF
   ↓
Kinesis Data Firehose
   ↓
S3 Bucket
```

---

# Configuration Strategy Pattern

|Variable|Controls|Effect|
|---|---|---|
|manage_route53_in_terraform|Hosted zone lifecycle|Terraform creates zone or not|
|route53_hosted_zone_id|DNS record destination|Identifies DNS container|
|waf_log_destination|WAF logging backend|Enables Firehose + S3 pipeline|

---

# Environment Flexibility

This tfvars setup allows:

- Using pre-existing DNS infrastructure
- Enabling/disabling logging features
- Deploying same Terraform module in multiple environments
- Switching logging strategies without changing core logic

---

# Mental Model

- tfvars = Environment configuration layer
- Code stays generic
- Variables control behavior
- Feature toggles enable modular infrastructure
