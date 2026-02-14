---
title: 04-private-ec2-and-endpoints
name: 04-private-ec2-and-endpoints
description: Private EC2 deployment in private subnet with ALB-only access, security group design, and Interface VPC Endpoint access controls.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - ec2
  - security-groups
  - vpc-endpoints
  - private-subnet
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

# 04-private-ec2-and-endpoints

---

![[media/image1.png]]

# Private EC2 Instance

This resource creates one EC2 instance inside your private subnet (so it won't have a public IP), and it bootstraps it at first boot using a script.

> ![[media/image2.png]]{width="3.1669411636045495in" height="0.2750240594925634in"}

---

## Subnet Placement

Puts the instance in your **first private subnet**.

### Private Subnet Characteristics

- **No public IP**
- Outbound internet only via **NAT Gateway** (if routes exist)
- Inbound access typically only from inside the VPC:
    - ALB
    - Bastion
    - VPN
    - SSM
    - Transit Gateway

---

![[media/image3.png]]

# Security Groups

Attaches the **private EC2 security group**.

This SG decides:

- What can connect *to* the instance
- What the instance can reach

---

# Security Group – Private App Instance

![[media/image4.png]]

---

## Inbound Rule – Allow HTTP Only From ALB

![[media/image5.png]]

Inbound to the private EC2 is allowed on **TCP 80**

But only if the source is the **ALB security group (`alb_sg`)**

### Behind-the-Load-Balancer Pattern

- People on the internet cannot directly hit your private EC2
- Only the ALB can reach it on port 80
- Direct access is blocked at the security group level

|Source|Port|Allowed?|
|---|---|---|
|Internet|80|❌ No|
|ALB SG|80|✅ Yes|
|Other SGs|80|❌ No|

---

## Outbound Rule – Allow All

![[media/image6.png]]

Private EC2 can send traffic **out to anywhere** (all ports/protocols).

This is common because outbound is usually controlled more by:

- Routing (NAT / endpoints)
- Network architecture

Rather than restrictive SG egress rules.

---

# Security Group – Interface VPC Endpoints

![[media/image7.png]]

This security group is meant to be attached to **Interface Endpoints (PrivateLink ENIs)**, such as:

- `com.amazonaws.<region>.ssm`
- `ssmmessages`
- `ec2messages`
- `secretsmanager`
- `logs`

These endpoints allow private EC2 instances to talk to AWS services **without using the internet or NAT**.

---

## Inbound Rule – Allow HTTPS (443) From Private EC2

![[media/image8.png]]

The endpoints will accept connections on **443**

But only if the caller is in `ec2_private_sg`.

|Source|Port|Purpose|
|---|---|---|
|ec2_private_sg|443|Access AWS APIs privately|

---

## Outbound Rule – Endpoint SG

![[media/image9.png]]

Allows those endpoint ENIs to send responses back out.

This ensures return traffic is permitted.

---

## Allow HTTPS From Lab EC2

![[media/image10.png]]

Same idea, but now your **public/lab EC2** (with SG `ec2_lab_sg`) can also use the interface endpoints.

So both:

- Private EC2
- Public Lab EC2

Can reach AWS services privately via VPC endpoints.

---

# Cross-VPC Access – São Paulo

![[media/image11.png]]

Allows any IP in `10.80.0.0/16` (your São Paulo VPC) to reach the private EC2 on port 80.

### Meaning

- São Paulo VPC is connected (likely via Transit Gateway)
- That CIDR is trusted
- Private EC2 now accepts HTTP traffic from that remote VPC

|Source|Port|Purpose|
|---|---|---|
|10.80.0.0/16|80|Cross-VPC application access|

---

# Architecture Flow (Private App)

```text
Internet
   ↓
ALB (Public Subnet)
   ↓
Private EC2 (Port 80)
   ↓
VPC Endpoints (443)
   ↓
AWS Services (SSM, Secrets Manager, Logs)
```

---

# Design Patterns Used

|Pattern|Purpose|
|---|---|
|Private Subnet Compute|No public exposure|
|ALB-only access|Controlled entry point|
|Interface Endpoints|Private AWS API access|
|SG-to-SG rules|Least privilege network design|
|CIDR-based cross-VPC rule|Multi-region connectivity|

---

# Mental Model

- Private EC2 = Not internet accessible
- ALB = Only approved ingress path
- VPC Endpoints = No NAT required for AWS services
- Security Groups = Application-level firewall
- Transit Gateway + CIDR rule = Cross-region communication
