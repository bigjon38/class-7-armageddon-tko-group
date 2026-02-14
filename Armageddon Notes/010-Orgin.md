---
title: 010-origin
name: 010-origin
description: CloudFront origin protection using managed prefix lists and secret header validation at the ALB listener level.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - alb
  - cloudfront
  - security
  - prefix-list
  - listener-rules
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

# 010-origin

---

![[image1.png]]

# CloudFront Origin Prefix List (Data Source)

This **does not create anything**.

It looks up an AWS-managed prefix list:

```text
com.amazonaws.global.cloudfront.origin-facing
```

This is a **published set of IP ranges** CloudFront uses when it connects to your origin.

---

## How It’s Used

Typically referenced in a security group rule like:

```text
Allow inbound 443 to ALB
ONLY from prefix_list_id
```

In this snippet, you're only defining the data source.<br>
The actual security group rule using it is elsewhere.

---

## Purpose

Lock your ALB down so:

- Random internet clients cannot hit it directly
- Only CloudFront IP ranges can connect

---

# Secret Origin Header Protection

---

![[image2.png]]

## Random Secret Header Value

Creates a **random 32-character string**:

- Letters + numbers
- `special = false` (no special characters)

Terraform stores it in state:

```text
random_password.armageddon_origin_header_value01.result
```

---

## Purpose

This becomes a **secret token** required on requests reaching the ALB.

CloudFront must be configured to send this header in origin settings.

---

![[image3.png]]

# Listener Rule – Allow Only Secret Header

Adds a rule to your **HTTPS listener**.

### Rule Details

- **Priority: 10**
- Condition: request must include header:

```text
King-Iron-Fist: <random-secret>
```

- Action: forward to target group (`armageddon_tg`)

---

## Why Priority 10?

Lower numbers = evaluated first.

This rule is checked before broader catch-all rules.

---

## Purpose

Even if someone reaches your ALB:

- They cannot reach your app
- Unless they know the secret header value

---

# Listener Rule – Block Everything Else

---

![[image4.png]]

Adds another rule to same listener.

### Rule Details

- Matches `/*` (all paths)
- Returns fixed **403 Forbidden**
- Priority: 99

---

## Evaluation Order

ALB processes rules in ascending priority:

|Priority|Condition|Result|
|---|---|---|
|10|Header matches|Forward to target group|
|99|Everything else|403 Forbidden|

---

# Full Protection Flow

```text
User
   ↓
CloudFront
   ↓ (adds secret header)
ALB (443)
   ↓
Header matches?
   ↓ Yes → Forward to EC2
   ↓ No  → 403 Forbidden
```

---

# Security Layers in Place

|Layer|Protection|
|---|---|
|Managed Prefix List|Only CloudFront IPs allowed|
|Secret Header|Only CloudFront-configured requests allowed|
|Priority Rules|Explicit allow, then deny-all|
|403 Default|Hard block for everything else|

---

# Defense-in-Depth Pattern

1. Network-level restriction (prefix list)
2. Application-layer secret header validation
3. Explicit deny fallback rule

This ensures:

- Direct ALB access is blocked
- Header spoofing alone isn’t enough (must come from allowed IP range)
- Only CloudFront-originated traffic reaches the application

---

# Mental Model

- Prefix list = "Only CloudFront can talk to ALB"
- Secret header = "Only CloudFront-configured traffic is valid"
- Catch-all 403 = "Everything else is denied"
- Priority controls rule evaluation order
