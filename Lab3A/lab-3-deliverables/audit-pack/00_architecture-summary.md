# Lab 3A — Architecture Summary
## APPI-Compliant Cross-Region Medical Application

### Overview
This system serves medical records to doctors globally while keeping all
patient data (PHI) physically stored in Japan, complying with Japan's
Personal Information Protection Act (APPI).

### Regional Roles

**Tokyo (ap-northeast-1) — Data Authority**
- RDS MySQL database (all PHI stored here only)
- Transit Gateway hub
- VPC: 10.10.0.0/16

**Sao Paulo (sa-east-1) — Stateless Compute**
- EC2 Auto Scaling Group (doctors access application here)
- Transit Gateway spoke
- VPC: 10.20.0.0/16
- No database. No PHI stored here.

### Traffic Flow
Doctor (Sao Paulo) --> CloudFront (kamaus-labs.online)
  --> Sao Paulo EC2 (stateless)
  --> Sao Paulo TGW --> [TGW Peering on AWS backbone]
  --> Tokyo TGW --> Tokyo VPC --> Tokyo RDS

### Compliance Controls
- RDS only in ap-northeast-1 (Tokyo)
- storage_encrypted = true (data at rest encrypted)
- RDS publicly_accessible = false
- CloudFront + WAF at edge (kamau-cf-waf01)
- TGW peering uses AWS private backbone only
- CloudTrail enabled in both regions

### Key Resource IDs
- CloudFront: E39DJ4MHDX6X1A
- Tokyo TGW: tgw-0c2bb4583fe0d21f4
- Sao Paulo TGW: tgw-0bbf081b853d39e85
- TGW Peering: tgw-attach-057a73fac87faaf56
- WAF: kamau-cf-waf01
- AWS Account: 533972479438
