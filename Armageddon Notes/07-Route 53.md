---
title: 07-route53-acm-logic
name: 07-route53-acm-logic
description: Flexible Route53 and ACM certificate logic supporting Terraform-managed or pre-existing hosted zones with automatic DNS validation handling.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - route53
  - acm
  - dns
  - locals
  - data-sources
type: notes
status: active
disabled rules:
---

## Configuration

[Linter Rules](https://chatgpt.com/g/g-68a60a81793c8191b6d623be5cf6efec-chicken-scratch/c/Linter-Rules.md)<br>
[Disabling Linter Rules](https://chatgpt.com/g/g-68a60a81793c8191b6d623be5cf6efec-chicken-scratch/c/Obsidian-Linter-Disabling-Rules)<br>
[Markdown Cheatsheet](https://chatgpt.com/g/g-68a60a81793c8191b6d623be5cf6efec-chicken-scratch/c/Markdown-Cheat-Sheet)

## Links

[00-Armageddon-Notes-Main]

---

# 07-route53-acm-logic

---

# Route53 Zone Logic

![[image1.png]]

## Locals – Zone Name & Zone ID

### armageddon_zone_name

Alias for your domain (example: `example.com`).

---

### armageddon_zone_id

Determines where DNS records should be created.

#### If `var.manage_route53_in_terraform = true`

- Terraform creates:

    ```text
    aws_route53_zone.armageddon_zone01
    ```

- Uses its `zone_id`.

#### If False

- Terraform does **not** create a hosted zone.
- You must supply:

    ```text
    var.route53_hosted_zone_id
    ```

---

### Key Design Pattern

Everything that creates DNS records references:

```text
local.armageddon_zone_id
```

This allows your code to work in both scenarios:

|Mode|Hosted Zone|
|---|---|
|Terraform-managed|Created by Terraform|
|External-managed|Pre-existing hosted zone|

---

# Existing ACM Certificate (Data Source)

![[image2.png]]

## Data "aws_acm_certificate"

This is a **data source** → "read something that already exists in AWS."

It runs only when:

```text
var.create_certificate = false
```

Because:

```text
count = var.create_certificate ? 0 : 1
```

---

### Search Criteria

- `domain = var.domain_name`
- `status = ISSUED`
- `most_recent = true`

### Outcome

If you're not creating a cert, Terraform grabs an **existing issued certificate ARN** for later use.

---

# Unified Certificate ARN Logic

![[image3.png]]

Creates a single "final answer" value:

```text
local.certificate_arn
```

---

## Why try()?

```text
try(..., null)
```

Prevents Terraform from erroring when:

- A resource doesn’t exist
- `count = 0` scenarios

---

## Two Possible Sources

### created_cert_arn

- Reads ARN from:

    ```text
    aws_acm_certificate_validation
    ```

- Meaning: You created + validated a new cert

---

### existing_cert_arn

- Reads ARN from:

    ```text
    data.aws_acm_certificate
    ```

- Meaning: You're using an already-issued cert

---

## coalesce(a, b)

Returns the **first non-null** value.

So:

- If new cert exists → use it
- Else → use existing cert

---

## Final Result

Other Terraform resources just use:

```text
local.certificate_arn
```

Without caring which path was taken.

---

# Hosted Zone Creation

![[image4.png]]

Hosted zone is created **only if**:

```text
manage_route53_in_terraform = true
```

If false:

- Terraform will not touch hosted zones
- But can still create records if you supply `route53_hosted_zone_id`

---

# ACM DNS Validation Records

![[image5.png]]

## When Are Records Created?

Only when:

```text
var.create_certificate = true
```

Otherwise:

```text
for_each = {}
```

Creates **zero records**.

---

## What Records Are Created?

When requesting an ACM certificate, AWS returns:

```text
domain_validation_options
```

These include required **CNAME records** for DNS validation.

The loop builds a map keyed by:

```text
dvo.domain_name
```

Useful when using SANs like:

- `example.com`
- `www.example.com`

---

## allow_overwrite = True

If validation record already exists:

- Terraform updates it
- Instead of failing with "record already exists"

---

## Where Are Records Created?

In the hosted zone defined by:

```text
local.armageddon_zone_id
```

Whether:

- Terraform-created
- Or externally provided

---

# Full Certificate Decision Flow

```text
create_certificate = true?
   ↓ Yes
Create ACM Cert
   ↓
Create DNS Validation Records
   ↓
Validate Certificate
   ↓
Use ARN

   ↓ No
Look up existing ISSUED cert
   ↓
Use ARN
```

---

# Design Patterns Used

|Pattern|Purpose|
|---|---|
|Conditional resource creation|Flexible deployments|
|Data source fallback|Reuse existing infrastructure|
|try() + coalesce()|Safe optional logic|
|Local abstraction|Clean downstream references|
|DNS validation automation|No manual CNAME steps|

---

# Mental Model

- One variable controls certificate strategy
- One local exposes final certificate ARN
- DNS creation logic adapts automatically
- Code works in greenfield or brownfield environments
