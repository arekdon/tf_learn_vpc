output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "aws_enable_dns_support" {
  value = aws_vpc.main.enable_dns_support
}

output "aws_enable_dns_hostnames" {
  value = aws_vpc.main.enable_dns_hostnames
}

output "aws_main_route_table_id" {
  value = aws_vpc.main.main_route_table_id
}