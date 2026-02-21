# Lab 2 – CloudFront Origin Cloaking Architecture

## Objective

Implement CloudFront as the only public ingress point for the application and enforce defense-in-depth security controls.

Target Architecture:

Internet  
→ CloudFront (WAF at edge)  
→ Application Load Balancer (restricted)  
→ EC2 (private application server)  
→ RDS  

---

## Security Controls Implemented

### 1. CloudFront Distribution
- Custom origin pointing to ALB
- HTTPS only to origin
- Viewer certificate from ACM (us-east-1)
- Domain aliases configured

### 2. WAF at the Edge
- AWS WAFv2 with scope = CLOUDFRONT
- AWS Managed Rules (CommonRuleSet)
- Associated directly to CloudFront distribution

### 3. Origin Cloaking (Defense-in-Depth)

**Layer 1 – Network Restriction**
- ALB security group allows inbound 443 only from:
  `com.amazonaws.global.cloudfront.origin-facing` prefix list

**Layer 2 – Secret Header Validation**
- CloudFront injects custom header:
  `X-Chewbacca-Growl`
- ALB listener rule forwards traffic only if header matches
- All other requests return HTTP 403

Result: Direct ALB access is blocked.

---

## DNS Configuration

- Route53 A record (apex) → CloudFront
- Route53 A record (app subdomain) → CloudFront
- Domain nameservers updated at registrar to Route53

---

## Verification Commands

### Verify CloudFront Access
```
curl -I https://kamaus-labs.online
```

Expected:
- HTTP/2 200
- x-cache: Miss/Hit from cloudfront

---

### Verify Direct ALB Access Blocked
```
curl -I --max-time 10 http://<ALB_DNS_NAME>
```

Expected:
- 403 or timeout

---

### Verify DNS Points to CloudFront
```
dig kamaus-labs.online A +short
```

Expected:
- CloudFront edge IP addresses

---

### Verify WAF Attached to CloudFront
```
aws cloudfront get-distribution --id <DISTRIBUTION_ID> \
--query "Distribution.DistributionConfig.WebACLId" \
--output text
```

Expected:
- WebACL ARN returned

---

## Key Concepts Reinforced

- CloudFront viewer certificates must be in us-east-1
- CloudFront WAF uses global (CLOUDFRONT) scope
- Prefix lists prevent hardcoding IP ranges
- Secret headers provide application-layer validation
- Terraform imports reconcile pre-existing AWS resources
- DNS authority depends on registrar nameservers

---

## Final Outcome

CloudFront is the only publicly accessible entry point.  
ALB cannot be accessed directly.  
WAF filters traffic before it reaches the VPC.  
Infrastructure is fully reproducible using Terraform.  
Verification evidence included in `/evidence`.

Lab 2 successfully completed.
