variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}
variable "postgres_subnet_cidr" {
  description = "CIDR block for Postgres subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for subnets"
  type        = string
  default     = "us-east-1a"
}
variable "my_ip_cidr" {
  description = "Your public IP with /32 mask to restrict SSH access"
  type        = string
  default     = "95.90.241.111/32"
}
variable "ami_id" {
  description = "AMI ID to use for EC2 instances"
  type        = string
  default     = "ami-053b0d53c279acc90"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the existing AWS key pair"
  type        = string
  default     = "ec2-server-virginia"
}
