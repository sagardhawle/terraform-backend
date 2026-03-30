provider "aws" {
  region = "us-east-2"
}

# connect backend #
terraform {
  backend "s3" {
    bucket = "sagar1234"
    key = "project-ec2-vpc/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "sagar-table"
    
  }
}






#------vpc create----#
resource "aws_vpc" "demo" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "demo-vpc"
  }

}


#public_subnet #
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.demo.id
  cidr_block = var.public_subnet
  availability_zone = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet"
  }
}


# private subnet #
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.demo.id
  cidr_block = var.private_subnet
  availability_zone = var.az
  tags = {
    Name = "private subnet "
  }
}



# igw create #
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "igw"
  }
}



# staic ip #
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "static ip"
  }
}


# create nat #
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "natgatway"
  }

}

# create route tables #
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# assocition route table #
resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id

}


# create private rute table #
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}


# route assoc #
resource "aws_route_table_association" "private_assoc" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}



# -------- SECURITY GROUP --------
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.demo.id  
  name = "ec2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
  Name = "my-sg"
}


}

# -------- EC2 INSTANCE --------
  # -------- EC2 --------
resource "aws_instance" "server" {
  ami           = data.aws_ami.latest.id
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              echo "Full Infra Working 🚀" > /var/www/html/index.html
              EOF

  tags = {
    Name = "VPC-EC2"
  }
} 
