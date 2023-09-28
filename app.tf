terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.18.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.74.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}



provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "ap-south-1"
}


resource "tls_private_key" "mytls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "mykey" {
  key_name   = "deployer-key-1"
  public_key = tls_private_key.mytls.public_key_openssh
}


output "mykey" {
  value     = tls_private_key.mytls.private_key_pem
  sensitive = true
}


resource "aws_security_group" "ssh-allow" {
  vpc_id = "vpc-007df13763776f546"
  ingress {
    description = "allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all the traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "myec2" {
  ami                    = "ami-0ff30663ed13c2290"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.mykey.id
  vpc_security_group_ids = [aws_security_group.ssh-allow.id]
  tags = {
    "OS" = "amazon"
  }
  provisioner "local-exec" {
    command = "terraform output -raw mykey > /tmp/mykey.pem; chmod 600 /tmp/mykey.pem"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i aws_ec2.yaml playbook.yaml"
  }
}




