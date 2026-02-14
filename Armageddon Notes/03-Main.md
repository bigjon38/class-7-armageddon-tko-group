---
title: 03-main
name: 03-main
description: Full Terraform VPC architecture including public/private subnets, NAT, Transit Gateway, EC2, RDS, IAM roles, Secrets Manager, SSM, and CloudWatch alerting.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - vpc
  - ec2
  - rds
  - iam
  - networking
  - cloudwatch
  - secrets-manager
  - ssm
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

# 03-main

---

# VPC Architecture Overview

---

![[image1.png]]

## VPC

Creates the VPC using `var.vpc_cidr` (example `10.30.0.0/16`).

Enables DNS features so instances can resolve DNS and get hostnames.

### Key Settings

|Setting|Purpose|
|---|---|
|enable_dns_support|Allows DNS resolution|
|enable_dns_hostnames|Assigns hostnames to instances|

---

![[image2.png]]

## Internet Gateway (IGW)

Attaches an **internet gateway** to the VPC.

Needed so **public subnets** can reach the internet.

---

![[image3.png]]

## NAT Gateway

NAT gateway sits in a **public subnet**.

Private subnets route `0.0.0.0/0` to NAT so private instances can<br>
**download updates**, etc., without being publicly reachable.

### Lab Vs Production

|Environment|NAT Design|
|---|---|
|Lab|One NAT in public[0] (single AZ)|
|Production|One NAT per AZ (high availability)|

---

![[image4.png]]

# Subnets

## Public Subnets

- Three public subnets
- Each in a different AZ
- `map_public_ip_on_launch = true`

EC2 launched here automatically gets a public IP.

## Private Subnets

- Three private subnets
- Each in a different AZ
- `map_public_ip_on_launch = false`

No public IPs assigned.

---

# CIDR Math

![[image5.png]]

If `var.vpc_cidr` is `/16`, adding 8 makes `/24` subnets.

### Example Layout

|Type|CIDR|
|---|---|
|Public 1|10.30.1.0/24|
|Public 2|10.30.2.0/24|
|Public 3|10.30.3.0/24|
|Private 1|10.30.11.0/24|
|Private 2|10.30.12.0/24|
|Private 3|10.30.13.0/24|

---

# Route Tables

---

![[image6.png]]

## Public Route Table

Public subnets can go out to the internet directly.

Route:

```text
0.0.0.0/0 → Internet Gateway
```

---

![[image7.png]]

## Private Route Table

Private subnets can go out to the internet **through NAT**.

Route:

```text
0.0.0.0/0 → NAT Gateway
```

---

# Transit Gateway

![[image8.png]]

Adds a route so anything in **private subnets** can reach<br>
`10.80.0.0/16` by going through the **Transit Gateway**.

---

# Security Groups

## EC2-lab-sg

### Inbound

|Port|Source|
|---|---|
|80 (HTTP)|Anywhere|
|22 (SSH)|One specific IP (My IP)|

### Outbound

- All traffic allowed

---

## RDS Security Group

Allows MySQL `3306` from:

- The EC2 lab SG (only EC2s in this SG can connect)
- São Paulo CIDR `10.80.0.0/16`

---

# RDS

---

![[image9.png]]

## RDS Subnet Group

Tells RDS to live inside your **private subnets** (best practice).

## DB Instance

- Creates a MySQL (or whatever `var.db_engine` is) DB
- Not publicly accessible
- Uses the RDS SG you defined

---

# EC2 Instance (Public)

![[image10.png]]

Launches an EC2 in the **first public subnet**<br>
(so it has internet + public IP)

Attaches an IAM instance profile so the EC2 can call AWS APIs<br>
(SSM, CloudWatch Logs, Secrets Manager, etc.)

Runs the `user_data.sh` bootstrap script at launch.

---

![[image11.png]]

Uses **Amazon Linux 2023 AMI** pulled dynamically from SSM.

---

# IAM Role + Instance Profile (Permissions for EC2)

An IAM role EC2 can assume<br>
(assume role policy for `ec2.amazonaws.com`)

### Custom Policies Attached

1. Read a specific secret<br>
    `secretsmanager:GetSecretValue` for `lab/rds/mysql*`
    
2. CloudWatch permissions
    
    - Logs APIs
    - SSM parameter reads for `AmazonCloudWatch-*`
        
3. SSM Managed Instance Core-like permissions<br>
    (so SSM Session Manager works)
    
4. Read-only access to specific SSM parameters<br>
    (endpoint / port / name)

---

![[image12.png]]

EC2 uses the instance profile to get those permissions.

---

# Secrets Manager (DB Connection Info)

![[image13.png]]

Creates a secret called:

```text
lab/rds/mysql
```

Stores a JSON payload containing:

- username
- password
- host
- port
- dbname

The EC2 role can read this (because a policy is attached for it).

---

# SSM Parameter Store

Creates 3 parameters:

- `lab-db-endpoint`
- `lab-db-port`
- `lab-db-name`

IAM permission attached so EC2 can read **those exact parameters**.

---

# CloudWatch Logging + Alerting

## Log Group

Creates log group:

```text
rds-app
```

Retention: 7 days

---

## Metric Filter

If logs contain the string:

```text
OperationalError
```

It increments custom metric:

```text
DBConnectionErrors
```

---

## Alarm

If:

```text
DBConnectionErrors >= 3 within 1 minute
```

Triggers alarm action.

---

## SNS

Creates SNS topic:

```text
db-incidents
```

Email subscription to `var.sns_email_endpoint`<br>
So you get alerted.

---

# Full Architecture Flow (Mental Model)

```text
Internet
   ↓
Internet Gateway
   ↓
Public Subnets (EC2)
   ↓
Private Subnets (RDS)
   ↓
NAT (outbound only)
   ↓
Transit Gateway (10.80.0.0/16)
```

---

# Architecture Pattern Summary

|Layer|Purpose|
|---|---|
|VPC|Network boundary|
|Public Subnets|Internet-facing resources|
|Private Subnets|Databases / internal services|
|NAT Gateway|Outbound-only internet for private resources|
|Transit Gateway|Connects to other networks|
|IAM Roles|Secure AWS API access|
|Secrets Manager|Store credentials securely|
|SSM|Config values + remote management|
|CloudWatch + SNS|Monitoring + alerting|

---

This is a **full production-style architecture pattern** covering:

- Multi-AZ networking
- Private database isolation
- IAM least privilege
- Secrets handling
- Observability and alerting
- Cross-network routing
