---
title: 05-vpc-endpoints
name: 05-vpc-endpoints
description: S3 Gateway endpoint and Interface VPC Endpoints (SSM, Logs, Secrets Manager, KMS) including route table behavior, DNS settings, subnet placement, and security group design.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - vpc-endpoints
  - s3
  - interface-endpoint
  - gateway-endpoint
  - networking
  - private-subnet
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

# 05-vpc-endpoints

---

![[media/image1.png]]

# S3 Gateway VPC Endpoint

## What It Creates

- An **S3 Gateway VPC endpoint** for your VPC.

---

## Why "Gateway" Matters

- **Gateway endpoints** are used for **S3 and DynamoDB only**.
- They **do not** create ENIs in subnets.
- They work by inserting routes into your **route tables** so traffic destined for S3 goes to the endpoint.

---

## Key Line

> ![[media/image2.png]]{width="4.467053805774278in" height="0.3166940069991251in"}

- This attaches the S3 endpoint to your **private route table**.
- Result: instances using that route table can reach S3 **without NAT Gateway or Internet Gateway**.

### Traffic Flow

```text
Private EC2
   ↓
Route Table
   ↓
S3 Gateway Endpoint
   ↓
S3 (Private AWS Backbone)
```

---

![[media/image3.png]]

---

# Local Values (Subnet Collections)

![[media/image4.png]]

## Collect All Private Subnet IDs

- Collects **all private subnet IDs** into one list.
- Used repeatedly so you don't retype `aws_subnet.private[*].id` everywhere.

### Pattern

```hcl
locals {
  private_subnet_ids = aws_subnet.private[*].id
}
```

---

![[media/image5.png]]

## Take First Two Private Subnets

- Takes only the **first two** private subnets.
- Common requirement for things like **Transit Gateway VPC attachments** (often "at least 2 AZs").

---

![[media/image6.png]]

![[media/image7.png]]

![[media/image8.png]]

# Interface VPC Endpoints

---

## Why "Interface" Matters

- **Interface endpoints** create **ENIs (network interfaces)** in the subnets you specify.
- Your instances talk to those ENIs over private IPs.

|Type|ENIs Created?|Uses Route Table?|Services|
|---|---|---|---|
|Gateway|❌ No|✅ Yes|S3, DynamoDB|
|Interface|✅ Yes|❌ No|Most AWS services|

---

## Private DNS Enabled

![[media/image9.png]]

This makes the standard AWS DNS name (like `ssm.<region>.amazonaws.com`) resolve to the **private endpoint IPs** inside your VPC.

Without this, you'd often need custom DNS handling.

### Result

- No code changes needed
- Default AWS SDK behavior works
- Traffic stays inside VPC

---

## Subnet Placement

![[media/image10.png]]

- You're placing endpoint ENIs in **every private subnet** (often one per AZ).
- This improves resilience: instances in any AZ have a "local" endpoint ENI.

---

## Security Group Requirement

Interface endpoints require an SG that controls who can connect to the endpoint ENIs.

Typically that SG:

- Allows **inbound 443 from your EC2 private SG**
- Allows outbound responses

---

![[media/image11.png]]

# CloudWatch Logs Endpoint

## What It Enables

Private instances can send logs to **CloudWatch Logs** privately via:

- CloudWatch Agent
- awslogs
- App log forwarders

Without this endpoint:

If there's no NAT/Internet path, CloudWatch log shipping usually fails.

---

![[media/image12.png]]

# Secrets Manager Endpoint

## What It Enables

Private instances can call Secrets Manager privately to:

- Fetch DB credentials at boot
- Rotate secrets (if configured)
- Avoid baking secrets into userdata

---

![[media/image13.png]]

# KMS Endpoint

## What It Enables

Private instances can call KMS for crypto operations, commonly:

- Decrypting secrets encrypted with KMS
- Using envelope encryption
- Interacting with services that require KMS calls from the instance side

---

# Full Private Connectivity Pattern

```text
Private EC2
   ↓
Interface Endpoints (ENIs)
   ↓
AWS Services (SSM, Logs, Secrets, KMS)
```

No NAT required.

---

# Architecture Summary

|Component|Purpose|
|---|---|
|S3 Gateway Endpoint|Private S3 access via route tables|
|Interface Endpoints|Private API access via ENIs|
|Private DNS|Makes standard AWS names resolve internally|
|Endpoint SG|Restricts which instances can connect|
|Multi-AZ placement|Improves availability|

---

# Mental Model

- Gateway endpoint = Route-table-based, S3/DynamoDB only
- Interface endpoint = ENI-based, most AWS services
- Private DNS = Transparent private access
- No NAT required for AWS service communication
- Security Groups enforce least privilege access
