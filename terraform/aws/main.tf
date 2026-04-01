terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "fiap_key" {
  key_name   = "fiap-chave-rm${var.rm_number}"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "ec2_sg" {
  name        = "sg-ec2-fiap-rm${var.rm_number}"
  description = "Security Group da instancia EC2 FIAP Multicloud"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name    = "sg-ec2-fiap-rm${var.rm_number}"
    Lab     = "FIAP-Multicloud"
    Aluno   = "rm${var.rm_number}"
    Managed = "terraform"
  }
}

resource "aws_instance" "fiap_site_aws" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.fiap_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo '<html><body style="font-family:Arial;background:#f0f4ff;text-align:center;padding:60px">
      <h1 style="color:#C8102E">FIAP Multicloud</h1>
      <h2>Servidor: AWS (Principal)</h2>
      <p>Se voce esta vendo esta pagina, a AWS esta funcionando.</p>
    </body></html>' > /var/www/html/index.html
  EOF

  tags = {
    Name    = "fiap-site-aws-rm${var.rm_number}"
    Lab     = "FIAP-Multicloud"
    Aluno   = "rm${var.rm_number}"
    Managed = "terraform"
  }
}
