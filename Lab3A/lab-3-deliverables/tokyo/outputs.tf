output "tokyo_tgw_id" {
  description = "Transit Gateway ID - Sao Paulo will peer with this"
  value       = aws_ec2_transit_gateway.shinjuku_tgw.id
}

output "tokyo_vpc_id" {
  description = "Tokyo VPC ID"
  value       = aws_vpc.shinjuku_vpc.id
}

output "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR - Sao Paulo needs this for routing"
  value       = aws_vpc.shinjuku_vpc.cidr_block
}

output "tokyo_rds_endpoint" {
  description = "RDS endpoint - Sao Paulo app connects here for all DB operations"
  value       = aws_db_instance.shinjuku_rds.endpoint
  sensitive   = true
}

output "tokyo_tgw_peering_attachment_id" {
  description = "Peering attachment ID - Sao Paulo uses this to accept"
  value       = aws_ec2_transit_gateway_peering_attachment.tokyo_to_saopaulo.id
}
