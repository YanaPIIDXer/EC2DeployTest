provider "aws" {
    region = "ap-northeast-1"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "EC2DeployTest"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "EC2DeployTest_Public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "EC3DeployTest_Public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
    name = "EC2DeployTest"
    description = "DeployTest"
    vpc_id = aws_vpc.main.id
    
    ingress {
        from_port        = 80
        to_port          = 80
        protocol         = "TCP"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port        = 22
        to_port          = 22
        protocol         = "TCP"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port        = 3389
        to_port          = 3389
        protocol         = "TCP"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_instance" "main" {
  ami           = "ami-09cf6a62116b95ed8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  key_name = "key"
  security_groups = [aws_security_group.sg.id]
  associate_public_ip_address = true

  tags = {
      Name = "EC2DeployTest"
  }
}

data "aws_route53_zone" "rdb_domain_zone" {
    name = "yanap-apptest.tk"
}

resource "aws_route53_record" "elb_domain_record" {
    zone_id = data.aws_route53_zone.rdb_domain_zone.zone_id
    name    = "ec2-deploy-test.yanap-apptest.tk"
    type    = "CNAME"
    ttl     = "300"
    records = [aws_instance.main.public_dns]
}
