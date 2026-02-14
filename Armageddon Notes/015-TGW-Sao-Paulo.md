---
title: 015-tgw-sao-paulo
name: 015-tgw-sao-paulo
description: São Paulo Transit Gateway creation, cross-region peering with Tokyo, VPC attachment, and TGW route configuration.
created: "02-14-2026"
time: "1:46 PM"
tags:
  - terraform
  - aws
  - transit-gateway
  - tgw
  - networking
  - multi-region
  - vpc
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

# 015-tgw-sao-paulo

---

![](media/image1.png)

# São Paulo Transit Gateway (TGW)

## What It Creates

A **Transit Gateway (TGW)** in the **São Paulo region**.

```text
provider = aws.saopaulo
```

---

## Why It Exists

A TGW acts as a **routing hub** that connects:

- Multiple VPCs
- VPN connections
- Peering attachments
- Cross-region TGWs

---

## Result

You now have a São Paulo TGW that can:

- Attach to the São Paulo VPC
- Peer with Tokyo’s TGW

---

![](media/image2.png)

# TGW Peering – Accepter Side (São Paulo)

## What It Does

Accepts a **Transit Gateway Peering Attachment** created from Tokyo.

---

## Cross-Region Peering = Two-Step Handshake

### Step 1 – Tokyo (Requester)

Creates:

```text
aws_ec2_transit_gateway_peering_attachment
```

### Step 2 – São Paulo (Accepter)

Accepts:

```text
aws_ec2_transit_gateway_peering_attachment_accepter
```

---

## Result

Cross-region TGW peering is now active from São Paulo’s perspective.

---

![](media/image3.png)

# São Paulo VPC Attachment

## What It Does

Attaches the São Paulo VPC:

```text
aws_vpc.sao_main_vpc
```

To the São Paulo TGW.

---

## Why Subnets Matter

The `subnet_ids` are where AWS places **TGW ENIs**.

### Best Practice

- Use **private subnets**
- Use **at least 2 AZs**

You're using:

```text
[0] and [1]
```

Which satisfies multi-AZ requirement.

---

## Result

Resources inside São Paulo VPC can now route traffic:

- To TGW
- From TGW

---

![](media/image4.png)

# TGW Route Configuration (São Paulo Side)

## What It Does

Adds a route to the São Paulo TGW route table:

```text
Destination: 10.30.0.0/16 (Tokyo CIDR)
Target: TGW Peering Attachment
```

---

## Where the Route Is Added

```text
association_default_route_table_id
```

Meaning:

- Attachments associated with the **default TGW route table**
- Automatically learn this route

---

## Result

São Paulo TGW knows:

To reach Tokyo network (`10.30.0.0/16`):

→ Send traffic over the TGW peering link.

---

# Full Cross-Region Flow

```text
São Paulo EC2
    ↓
São Paulo VPC
    ↓
São Paulo TGW
    ↓ (Peering)
Tokyo TGW
    ↓
Tokyo VPC
    ↓
Tokyo Resources
```

---

# Architecture Pattern

|Component|Role|
|---|---|
|São Paulo TGW|Regional routing hub|
|Peering Attachment|Cross-region link|
|VPC Attachment|Connects VPC to TGW|
|TGW Route|Directs traffic to Tokyo CIDR|
|Multi-AZ Subnets|High availability|

---

# Mental Model

- TGW = Layer 3 routing hub
- Peering = Cross-region backbone
- Attachments = Connect VPCs to TGW
- TGW route tables control inter-VPC reachability
- Both regions must configure routes for full connectivity
