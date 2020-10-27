 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
#shared_credentials_file = "/home/tf_user/.aws/creds"
}

variable "vpc_id" {
  default = "vpc-4d2a8527"
}

variable "image_id" {
  default = "ami-0fefc541a9298d8c0"
}

variable "subnet_id" {
  default = "subnet-1109d95d"
}

resource "aws_security_group" "ubuntu" {
  name        = "msecurity_group"
  vpc_id      = "${var.vpc_id}"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
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
    Name = "terraform"
  }
}

resource "aws_instance" "ubuntu" {
  ami           = "${var.image_id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = "${aws_security_group.ubuntu.id}"

  key_name      = aws_key_pair.ubuntu.key_name

  subnet_id = "${subnet_id}"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("key")
    host        = self.public_ip
  }
}