output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "ecs_security_group_ids" {
  value       = { for env, sg in aws_security_group.ecs_tasks : env => sg.id }
  description = "Map of environment name to ECS task security group ID"
}
