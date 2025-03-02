# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "default-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "default-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "default-private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "GateWay" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "default-GW"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GateWay.id
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway (This is needed for NAT Gateway)
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway - enables instances in the private subnet to communicate with the internet through the NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "default-nat-gateway"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = aws_nat_gateway.nat.id
  }
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private.id
}

# Security Group for Kubernetes EC2 instance
resource "aws_security_group" "kubernetes_sg" {
  name        = "kubernetes_sg"
  description = "Security group for Kubernetes EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 instance for Kubernetes in private subnet
resource "aws_instance" "kubernetes_instance" {
  ami           = "ami-0e731c8a588258d0d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet.id
  key_name      = "EC2_EKS"
  vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
}
