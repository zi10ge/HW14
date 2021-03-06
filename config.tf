 
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
}

variable "key_id" {}
variable "key_sec" {}


variable "vpc_id" {
  default = "vpc-4d2a8527"
}

variable "image_id" {
  default = "ami-092391a11f8aa4b7b"
}

variable "subnet_id" {
  default = "subnet-1109d95d"
}

variable "key_name" {
  default = "test1"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.example.public_key_openssh}"
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
    Name = "my terraform"
  }
}

#
#resource "local_file" "cloud_pem" { 
#  filename = "${path.module}/cloudtls.pem"
#  content =  "${tls_private_key.example.private_key_pem}"
#}

resource "aws_instance" "build_instance" {
  ami                    = "${var.image_id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ubuntu.id}"]
  subnet_id              = "${var.subnet_id}"
  key_name               = "${aws_key_pair.generated_key.key_name}"
  count                  = 1
  associate_public_ip_address = true 
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y default-jdk git maven awscli
git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
mvn package -f ./boxfuse-sample-java-war-hello/pom.xml
aws configure set aws_access_key_id ${var.key_id}
aws configure set aws_secret_access_key ${var.key_sec}
aws configure set default.region eu-central-1
aws s3 cp ./boxfuse-sample-java-war-hello/target/hello-1.0.war s3://mywebapp.test.ru
EOF
}

resource "aws_instance" "webapp_instance" {
  ami                    = "${var.image_id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ubuntu.id}"]
  subnet_id              = "${var.subnet_id}"
  key_name               = "${aws_key_pair.generated_key.key_name}"
  count                  = 1
  associate_public_ip_address = true 
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y tomcat8 awscli
aws configure set aws_access_key_id ${var.key_id}
aws configure set aws_secret_access_key ${var.key_sec}
aws configure set default.region eu-central-1
while true; do if (aws s3 ls s3://mywebapp.test.ru/ | grep hello-1.0.war) > /tmp/test.txt; then break; else echo 0; fi; sleep 5; done;
aws s3 cp s3://mywebapp.test.ru/hello-1.0.war /var/lib/tomcat8/webapps/hello-1.0.war
EOF
}
