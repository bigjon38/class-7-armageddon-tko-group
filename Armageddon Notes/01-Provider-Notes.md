---
title: 01-Provider-Notes
description: Notes on Terraform AWS provider configurations including default and aliased providers with common multi-region use cases.
created: 02-14-2026
time: 1:46 PM
tags:
  - terraform
  - aws
  - provider
  - multi-region
  - acm
  - cloudfront
type: notes
status: active
disabled rules:
---


## Links

[00-Armageddon-Notes-Main](00-Armageddon-Notes-Main.md)

---

# 01-Provider-Notes

---

# Provider Configurations (Terraform + AWS)

---

## Default Provider

![](media/image1.png)

This is the **default** AWS provider configuration.

Any AWS resource that **doesn't** specify a `provider = ...` will use this one.

### Key Concept

|Scenario|Behavior|
|---|---|
|Resource has no `provider` argument|Uses default provider|
|Only one provider block exists|All resources use it|
|Multiple providers exist but no alias specified|Default is used|

### Example

```hcl
provider "aws" {
  region = "us-west-2"
}
```

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

> The S3 bucket will be created in **us-west-2** because no provider was specified.

---

## Aliased Provider

![](media/image2.png)

This is a **second** AWS provider configuration.

You use it when you want specific resources created in another region.

### Why Use Aliases?

- Multi-region deployments
- Cross-region replication
- Global services with region constraints
- Special service requirements

### Example

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}
```

Then reference it:

```hcl
resource "aws_s3_bucket" "east_bucket" {
  provider = aws.east
  bucket   = "my-east-bucket"
}
```

---

## Aliased Provider (US East 1)

![](media/image3.png)

Common reason in your setups:

**ACM certificates for CloudFront must be in us-east-1**

So you often place certificate resources here.

Sometimes also used for:

- Route 53-related workflows
- Global service integrations
- Cross-region failover setups

---

## Real-World Pattern

|Resource Type|Typical Region|Why|
|---|---|---|
|Application Infrastructure|Primary region (e.g., us-west-2)|Where app runs|
|ACM for CloudFront|us-east-1|CloudFront requirement|
|Route 53|Global (managed via us-east-1 workflows)|DNS service|
|Replication targets|Secondary region|DR / HA strategy|

---

## Mental Model

- **Default provider** = main deployment region
- **Aliased provider** = special-purpose or secondary region
- Resources explicitly reference aliases when region-specific behavior is required

---

## Quick Exam Recall

- No `provider` specified → Uses **default**
- `provider = aws.alias_name` → Uses **aliased provider**
- CloudFront + ACM → **Certificate must be in us-east-1**
- Multiple regions → Use provider aliases

---
