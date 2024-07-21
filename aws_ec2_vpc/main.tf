terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# This will create a VPC 
# The 24 will give 256 Ips
# The 8 will give the most number of IPs

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "public-subnet"
  }
}
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "main_route_table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.route_table.id
}


# Create a security group
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id
  # THis is SSH traffic 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # This is HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web"
  }
}


resource "aws_security_group" "private_group" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_group"
  }
}

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = "main"
  }
}

resource "aws_network_acl_association" "NACL_association" {
  subnet_id      = aws_subnet.public.id
  network_acl_id = aws_network_acl.main.id

}

resource "aws_instance" "public_ec2" {
  ami           = "ami-04e914639d0cca79a"
  instance_type = "t2.micro"

  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.web.id]

  tags = {
    Name = "Public"
  }
}



resource "aws_instance" "private_ec2" {
  ami           = "ami-04e914639d0cca79a"
  instance_type = "t2.micro"

  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.private_group.id]

  tags = {
    Name = "Private"
  }
}


output "ec2_public" {
  value = [aws_instance.public_ec2.public_ip]
}