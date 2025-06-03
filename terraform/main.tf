provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "marline-devops-vpc"
  }
}

# Public Subnet - for Vote/Result and Bastion (with public IP)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  map_public_ip_on_launch = true

  tags = {
    Name = "marline-public-subnet"
  }
}

# Private Subnet - for Redis/Worker and PostgreSQL (no public IP)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  map_public_ip_on_launch = false

  tags = {
    Name = "marline-private-subnet"
  }
}

# Internet Gateway attached to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "marline-main-igw"
  }
}
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "marline-nat-eip"
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "marline-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "marline-public-rt"
  }
}

# Route for Internet access in the public route table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
# Associate public subnet with public route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# Private Route Table (no IGW route)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "marline-private-rt"
  }
}
# Associate private subnet with private route table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_security_group" "vote_result_sg" {
  name        = "marline-vote_result_sg"
  description = "Allow HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow Redis outbound"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    description = "Allow Postgres outbound (optional)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }
  tags = {
    Name = "marline-vote_result_sg"
  }
}

resource "aws_security_group" "redis_worker_sg" {
  name        = "marline-redis_worker_sg"
  description = "Allow Redis traffic only from Vote/Result SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Redis from Vote/Result SG"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.vote_result_sg.id]
  }
  ingress {
    description     = "Allow SSH from Bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    description = "Allow Postgres outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "marline-redis_worker_sg"
  }
}
resource "aws_security_group" "postgres_sg" {
  name        = "marline-postgres_sg"
  description = "Allow Postgres traffic only from Redis/Worker SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Postgres from Redis/Worker SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_worker_sg.id]
  }
  ingress {
    description     = "Allow SSH from Bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "marline-postgres_sg"
  }
}
resource "aws_security_group" "bastion_sg" {
  name        = "marline-bastion_sg"
  description = "Allow SSH from my IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "marline-bastion_sg"
  }
}
resource "aws_instance" "bastion_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  tags = {
    Name = "marline-bastion-host"
  }
}
resource "aws_instance" "vote_result_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.vote_result_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  tags = {
    Name = "marline-vote-result"
  }
}
resource "aws_instance" "redis_worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.redis_worker_sg.id]
  associate_public_ip_address = false
  key_name                    = var.key_pair_name

  tags = {
    Name = "marline-redis-worker"
  }
}
resource "aws_instance" "postgres" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.postgres_sg.id]
  associate_public_ip_address = false
  key_name                    = var.key_pair_name

  tags = {
    Name = "marline-postgres-db"
  }
}
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "marline-terraform-state"
  force_destroy = true

  tags = {
    Name = "marline-terraform-state"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "marline-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "marline-terraform-lock"
  }
}



