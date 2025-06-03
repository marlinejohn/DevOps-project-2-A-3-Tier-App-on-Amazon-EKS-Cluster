output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}
output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}
output "vote_result_sg_id" {
  description = "ID of Vote/Result Security Group"
  value       = aws_security_group.vote_result_sg.id
}

output "redis_worker_sg_id" {
  description = "ID of Redis/Worker Security Group"
  value       = aws_security_group.redis_worker_sg.id
}
output "postgres_sg_id" {
  description = "ID of Postgres Security Group"
  value       = aws_security_group.postgres_sg.id
}
output "bastion_sg_id" {
  description = "ID of Bastion Security Group"
  value       = aws_security_group.bastion_sg.id
}
output "vote_result_public_ip" {
  description = "Public IP of Vote/Result App"
  value       = aws_instance.vote_result_app.public_ip
}
output "redis_worker_private_ip" {
  description = "Private IP of Redis/Worker"
  value       = aws_instance.redis_worker.private_ip
}
output "postgres_private_ip" {
  description = "Private IP of PostgreSQL instance"
  value       = aws_instance.postgres.private_ip
}
