output "public_subnet" {
  value = aws_subnet.public.id
}

output "private_subnet" {
  value = aws_subnet.private.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.db_subnet.id
}

output "network_interface_id" {
  value = aws_network_interface.net_interface.id
}