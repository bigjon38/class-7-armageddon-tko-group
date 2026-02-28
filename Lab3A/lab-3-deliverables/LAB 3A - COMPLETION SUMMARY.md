LAB 3A - COMPLETION SUMMARY
Cross-Region Architecture with Transit Gateway (APPI-Compliant)
Student: Kamau  |  Date: February 22, 2026  |  AWS Account: 533972479438

1. What You Built
You designed and deployed a fully compliant cross-region medical application on AWS. The architecture separates data storage (Tokyo) from compute (Sao Paulo), connected by a private encrypted tunnel, satisfying Japan's APPI privacy law while allowing global access.

Resource
Region
Purpose
shinjuku-vpc
ap-northeast-1 (Tokyo)
Primary VPC - data authority
shinjuku-rds
ap-northeast-1 (Tokyo)
MySQL DB - all PHI lives here only
shinjuku-tgw
ap-northeast-1 (Tokyo)
Transit Gateway hub
liberdade-vpc
sa-east-1 (Sao Paulo)
Secondary VPC - stateless compute
liberdade-asg
sa-east-1 (Sao Paulo)
Auto Scaling Group - EC2 for doctors
liberdade-tgw
sa-east-1 (Sao Paulo)
Transit Gateway spoke
TGW Peering
Cross-region
Encrypted private tunnel on AWS backbone

1. How Traffic Flows
Every request from a doctor in Brazil follows this exact path. The data never leaves Japan.

Doctor (Sao Paulo) --> kamaus-labs.online (CloudFront)
  --> Sao Paulo EC2 (stateless - processes request)
  --> Sao Paulo TGW --> [TGW Peering on AWS backbone]
  --> Tokyo TGW --> Tokyo VPC --> Tokyo RDS
  --> Data returned back up the same path to the doctor

Key principle: Access is global. Storage is local. Patient data physically never leaves Japan.

1. Resources Deployed
Tokyo (ap-northeast-1) - 20 Resources
Resource Type
Name / Details
aws_vpc
shinjuku-vpc (10.10.0.0/16)
aws_subnet x4
2 public + 2 private across AZs 1a and 1c
aws_internet_gateway
shinjuku-igw
aws_nat_gateway + aws_eip
shinjuku-nat in public subnet 1a
aws_route_table x2
shinjuku-public-rt + shinjuku-private-rt
aws_route_table_association x4
Linked all subnets to route tables
aws_security_group x2
shinjuku-app-sg + shinjuku-rds-sg
aws_db_subnet_group
shinjuku-db-subnet-group (private subnets)
aws_db_instance
shinjuku-rds (MySQL 8.0, encrypted at rest)
aws_ec2_transit_gateway
shinjuku-tgw
aws_ec2_transit_gateway_vpc_attachment
shinjuku-tgw-attachment
aws_ec2_transit_gateway_peering_attachment
shinjuku-to-liberdade-peering

Sao Paulo (sa-east-1) - 19 Resources
Resource Type
Name / Details
aws_vpc
liberdade-vpc (10.20.0.0/16)
aws_subnet x4
2 public + 2 private across AZs 1a and 1c
aws_internet_gateway
liberdade-igw
aws_nat_gateway + aws_eip
liberdade-nat in public subnet 1a
aws_route_table x2
liberdade-public-rt + liberdade-private-rt
aws_route_table_association x4
Linked all subnets to route tables
aws_security_group
liberdade-app-sg (no RDS SG - no DB here)
aws_launch_template
liberdade-lt (injects Tokyo RDS endpoint via user_data)
aws_autoscaling_group
liberdade-asg (min 1, max 3, t3.micro)
aws_ec2_transit_gateway
liberdade-tgw
aws_ec2_transit_gateway_vpc_attachment
liberdade-tgw-attachment
aws_ec2_transit_gateway_peering_attachment_accepter
Accepted Tokyo peering request

1. Verification Results
Check
Result
TGW peering state - Tokyo
available
TGW peering state - Sao Paulo
available
RDS instances in Sao Paulo
NONE - confirmed empty (APPI compliant)
RDS instance in Tokyo
terraform-20260222211311472000000002
Tokyo TGW ID
tgw-0c2bb4583fe0d21f4
Sao Paulo TGW ID
tgw-0cb4636af59e74b95
Peering Attachment ID
tgw-attach-06f592be2b934be1e

2. Errors You Hit and Fixed
These are not failures. Hitting and debugging real errors is how engineers learn. Each one maps to a real exam concept.

Error 1 - Duplicate resource in outputs.tf
Infrastructure code was accidentally pasted into outputs.tf causing duplicate resource declarations.
Fix: Deleted all content from outputs.tf and kept only output blocks. Each .tf file in a folder shares one namespace.
SAA Lesson: Terraform treats all .tf files in a folder as one module. Resource names must be unique per type across all files.

Error 2 - TGW Peering Attachment Invalid ID
Tokyo tried to create a peering attachment to Sao Paulo before Sao Paulo's TGW existed. AWS returned InvalidTransitGatewayID.Malformed.
Fix: Used terraform apply -target to deploy Sao Paulo's TGW first, retrieved its ID, then updated Tokyo's tfvars and re-applied.
SAA Lesson: TGW peering requires both TGWs to exist before the attachment can be created. Multi-region deployments always have dependency ordering challenges.

Error 3 - Smart Quotes in Terminal
Copy-pasted commands used curly quotes which Terminal read as unclosed strings, producing a dquote> prompt.
Fix: Used a terraform.tfvars file to pass variable values instead of inline -var flags.
SAA Lesson: Sensitive values (passwords, IDs) belong in .tfvars files, not in terminal commands. This is also a security best practice.

1. SAA Exam Notes - Study These
Every concept below appeared directly in this lab. These are high-frequency SAA exam topics.

Transit Gateway
TGW is regional - you cannot directly attach a VPC from another region
Cross-region connectivity requires TGW Peering Attachments between two TGWs
TGW peering traffic stays on the AWS private backbone - never public internet
Each VPC attaches to its LOCAL TGW only - TGWs peer with each other
TGW supports: VPC, VPN, Direct Connect Gateway, and peering attachments
TGW route tables control which attachments can communicate with each other

TGW vs VPC Peering - Know This Cold
Feature
VPC Peering
Transit Gateway
Topology
1-to-1 only
Hub-and-spoke (many VPCs)
Transitive routing
NOT supported
Supported via route tables
Cross-region
Supported (inter-region peering)
Supported via TGW peering
Cost
Lower for simple use cases
Higher but scales better
Auditability
Harder to audit at scale
Centralized, clear traffic paths
When to use
Simple 2-VPC connection
Enterprise, compliance, many VPCs

VPC Networking
Public subnet = route table has 0.0.0.0/0 pointing to Internet Gateway
Private subnet = route table has 0.0.0.0/0 pointing to NAT Gateway
NAT Gateway MUST be placed in a public subnet - very common exam trap
NAT Gateway needs an Elastic IP to communicate with the internet
Route tables are attached to subnets, not to VPCs
Always use multiple AZs for high availability - this lab used 1a and 1c

RDS
Always deploy RDS in private subnets - never publicly_accessible = true in production
RDS requires a DB Subnet Group spanning at least 2 Availability Zones
storage_encrypted = true encrypts data at rest - required for APPI and HIPAA
Security Groups on RDS should allow only specific CIDRs - never 0.0.0.0/0
SG rules reference CIDRs across VPCs - you cannot reference SG IDs from other VPCs
In this lab: RDS SG allows Tokyo app subnets AND Sao Paulo VPC CIDR (10.20.0.0/16) via TGW

CloudFront
CloudFront is a CDN - it does NOT store data, it caches content at edge locations globally
Terminates TLS at the edge - encrypts traffic between user and CloudFront
WAF rules can be applied at CloudFront before traffic reaches your origin
Does NOT violate data residency laws because it does not persist PHI
Cache-Control headers on responses control what CloudFront is allowed to cache
Origin options: ALB, EC2, S3, API Gateway, or custom HTTP endpoint

Security Groups vs NACLs
Feature
Security Groups
NACLs
State
Stateful - return traffic auto-allowed
Stateless - must allow both directions
Level
Instance / ENI level
Subnet level
Rules
ALLOW only - no deny
ALLOW and DENY
Evaluation
All rules evaluated together
Rules evaluated in number order
Default
Deny all inbound, allow all outbound
Allow all inbound and outbound

Data Residency and Compliance
APPI (Japan): patient data must be physically stored inside Japan
HIPAA (US): healthcare data must be encrypted at rest and in transit
GDPR (EU): personal data of EU citizens must comply with EU rules regardless of storage location
Architecture pattern: separate compute from storage to enable global access with local data residency
CloudFront at the edge, stateless EC2 regionally, RDS only in the jurisdiction - this is the pattern

1. Terraform Concepts You Used
Command / Concept
What It Does
terraform init
Downloads providers and sets up the working directory
terraform plan
Shows what will be created, changed, or destroyed - no actual changes made
terraform apply
Builds the infrastructure - requires typing 'yes' to confirm
terraform destroy
Tears down all resources tracked in state
terraform state list
Shows all resources currently tracked in the state file
terraform output
Displays output values defined in outputs.tf
-target flag
Applies only specific named resources - useful for dependency ordering
terraform.tfvars
File for variable values - keeps sensitive values out of terminal commands
sensitive = true
Marks an output as sensitive so it is hidden in terminal output
remote state data source
Reads another stack's state file so stacks can share output values
depends_on
Explicitly tells Terraform one resource depends on another
data sources
Reads existing resources or external state without managing them

2. Your Interview Answer
"I designed a cross-region medical system where all PHI remained in Japan to comply with APPI. Tokyo hosted the database, Sao Paulo ran stateless compute, and Transit Gateway provided a controlled data corridor. CloudFront delivered a single global URL without violating data residency."
That answer demonstrates compliance knowledge, multi-region architecture, network design, and the ability to explain tradeoffs to security and legal teams. That is Senior Engineer territory.

3. Next Steps
Run the connectivity test: SSM into Sao Paulo EC2, run: nc -vz <tokyo-rds-endpoint> 3306
Add ALB in front of Sao Paulo ASG and connect it to your CloudFront distribution
Store RDS credentials in Secrets Manager and reference them from EC2 user_data
Study TGW route tables - understand how to control which attachments can route to each other
Study VPC endpoints - how to access AWS services privately without internet traffic
Practice explaining this architecture out loud in 60 seconds

Lab 3A Complete  |  39 Resources Deployed Across 2 Regions  |  APPI Compliant  |  February 22, 2026
