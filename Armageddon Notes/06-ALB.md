---
title: 06-alb-cloudfront-waf
name: 06-alb-cloudfront-waf
description: Internet-facing ALB behind CloudFront with origin cloaking, target groups, ACM TLS, WAF protection, CloudWatch alarms, and dashboard monitoring.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - alb
  - cloudfront
  - waf
  - acm
  - cloudwatch
  - sns
  - load-balancing
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

# 06-alb-cloudfront-waf

---

# ALB Security Group

![[image1.png]]

Creates a **security group** named `alb-sg` inside your VPC<br>
(`aws_vpc.main_vpc.id`).

Think: **"the firewall rules container for the load balancer."**

---

![[image2.png]]

## Inbound – HTTPS Only From CloudFront

Allows incoming **TCP 443 (HTTPS)** to the ALB security group only from CloudFront using a managed prefix list:

![[image3.png]]

This prefix list represents AWS-managed **CloudFront origin-facing IP ranges**<br>
(or a custom managed prefix list representing CloudFront).

### Origin Cloaking Pattern

Users hit **CloudFront** → CloudFront hits **ALB**<br>
Random internet hosts cannot hit your ALB directly on 443.

```text
Internet User
     ↓
CloudFront
     ↓ (443)
ALB
```

---

![[image4.png]]

## ALB → Private EC2 (HTTP 80)

Allows the ALB to send **TCP 80 (HTTP)** traffic to your private EC2 instances, but only to instances in:

```text
aws_security_group.ec2_private_sg
```

### Tight Rule Design

|Source|Destination|Port|
|---|---|---|
|ALB SG|EC2 Private SG|80|

Net effect:

```text
CloudFront → (443) → ALB → (80) → Private EC2
```

---

# Application Load Balancer

![[image5.png]]

## aws_lb "armageddon_alb"

Creates an **internet-facing Application Load Balancer**:

- `internal = false` → Public ALB
- `security_groups = [alb_sg]`
- `subnets = slice(aws_subnet.public[*].id, 0, 2)`

### Why slice(..., 0, 2)?

ALBs require **at least 2 subnets in different AZs**.

This places the ALB in the first two public subnets.

---

## Access Logs

Conditionally enabled:

- Logs stored in:

    ```text
    aws_s3_bucket.armageddon_alb_logs_bucket[0].bucket
    ```

- `enabled = var.enable_alb_access_logs`
- `prefix = var.alb_access_logs_prefix`

The `[0]` implies the S3 bucket was created using `count = 1`.

---

# Target Group

![[image6.png]]

## aws_lb_target_group "armageddon_tg"

- HTTP on port 80
- Associated with your VPC

### Health Check Configuration

|Setting|Value|
|---|---|
|Path|`/`|
|Protocol|HTTP|
|Interval|30s|
|Timeout|5s|
|Healthy Threshold|2|
|Unhealthy Threshold|2|
|Accepted Codes|200–399|

This must match what your instance serves on `/`.

---

![[image7.png]]

## Target Group Attachment

Attaches a **single EC2 instance**:

- `target_id = aws_instance.ec2_private_b.id`
- `port = 80`

This is **instance-target mode** (not IP targets, not ASG).

---

# ACM Certificate

![[image8.png]]

## aws_acm_certificate "armageddon_acm_cert01"

Created only if `var.create_certificate = true`.

- Primary domain: `var.domain_name`
- SAN: `*.${var.domain_name}`
- Validation method: DNS or EMAIL

---

![[image9.png]]

## DNS Certificate Validation

If using DNS:

```text
validation_record_fqdns = [
  for r in aws_route53_record.armageddon_record : r.fqdn
]
```

Ensures Route 53 validation records exist.

---

# Listeners

---

![[image10.png]]

## HTTP Listener (Port 80)

Redirects all traffic to HTTPS (443).

Ensures:

```text
http://example.com → https://example.com
```

---

![[image11.png]]

## HTTPS Listener (Port 443)

- `ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"`
- `certificate_arn = local.certificate_arn`
- Forwards to target group

### Dependency

```text
depends_on = [
  aws_acm_certificate_validation.armageddon_acm_validation01
]
```

Ensures certificate is validated before listener creation.

---

# WAF Protection

![[image12.png]]

## aws_wafv2_web_acl "armageddon_waf"

Created only if `var.enable_waf = true`.

- Scope: Regional
- Default action: Allow
- Managed rule group: `AWSManagedRulesCommonRuleSet`
- CloudWatch metrics enabled

Blocks common attack patterns.

---

![[image13.png]]

## WAF Association

Associates WAF with ALB:

```text
resource_arn = aws_lb.armageddon_alb.arn
```

WAF protects ALB (regional scope), not CloudFront.

---

# ALB Monitoring

---

![[image14.png]]

## ALB 5XX Alarm

Creates CloudWatch alarm on:

- Namespace: `AWS/ApplicationELB`
- Metric: `HTTPCode_ELB_5XX_Count`
- Statistic: Sum
- Dimension:

    ```text
    LoadBalancer = aws_lb.armageddon_alb.arn_suffix
    ```

Triggers when:

- Metric ≥ `var.alb_5xx_threshold`
- For `var.alb_5xx_evaluation_periods`
- Period = `var.alb_5xx_period_seconds`

Publishes to:

```text
aws_sns_topic.lab_db_incidents.arn
```

Alerts when ALB generates 5xx responses<br>
(often target failures or app errors).

---

![[image15.png]]

# CloudWatch Dashboard

## aws_cloudwatch_dashboard "armageddon_dashboard"

Creates dashboard with two widgets:

### Widget 1 – Requests + 5XX

- `RequestCount`
- `HTTPCode_ELB_5XX_Count`

### Widget 2 – TargetResponseTime

- Average latency from ALB → targets

Uses:

```text
aws_lb.armageddon_alb.arn_suffix
```

To identify correct ALB dimension.

---

# Full Traffic & Protection Flow

```text
User
   ↓
CloudFront
   ↓ (443 only)
ALB (WAF Protected)
   ↓ (80)
Private EC2
```

---

# Architecture Summary

|Layer|Purpose|
|---|---|
|CloudFront|Edge caching + origin cloaking|
|ALB|L7 routing + TLS termination|
|ACM|Certificate management|
|WAF|Layer 7 protection|
|Target Group|Health checks + routing|
|SNS Alarm|Failure notification|
|Dashboard|Operational visibility|

---

# Design Patterns Used

- Origin cloaking via CloudFront prefix list
- ALB-only backend access
- TLS enforcement + redirect
- Managed WAF protections
- Conditional resource creation
- Observability with alarms + dashboards
