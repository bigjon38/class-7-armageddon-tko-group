# Auditor Narrative — APPI Compliance Statement

This system was designed to comply with Japan's Personal Information Protection
Act (APPI), which requires that Japanese patient medical data be physically
stored inside Japan. To meet this requirement, we separated the architecture
into two distinct roles across two AWS regions. Tokyo (ap-northeast-1) serves
as the data authority — it is the only region where the RDS database exists,
meaning all patient health information (PHI) is written to and read from Japan
only. Sao Paulo (sa-east-1) runs stateless compute only, meaning the
application servers there process requests but never store patient data locally.
When a doctor in Brazil accesses a patient record, their request travels through
CloudFront at the edge, hits a Sao Paulo EC2 instance, and is forwarded through
an AWS Transit Gateway peering connection directly to the Tokyo database over
AWS's private backbone — never the public internet. The database cannot be
placed outside Tokyo because doing so would violate APPI, even if the data were
encrypted, because the law governs physical storage location, not just access
controls. The evidence in this audit pack proves the assertion: RDS exists only
in ap-northeast-1, the TGW corridor is the only cross-region path, CloudFront
and WAF sit at the edge, and CloudTrail records every configuration change made
to the system.
