
variable "ami" { default = "ami-03338e1f67dae0168" }
variable "ami_type" { default = "c5.24xlarge" }
variable "region" { default = "ca-central-1" }
variable "transit" { default = "none" }
variable "owner" { default = "vguerlesquin" }
variable "project" { default = "Video Converter" }
variable "tower" { default = "none"}


provider "aws" {
  region = var.region
}



resource "random_uuid" "uuid" {}

resource "tls_private_key" "auto-gen-key-ffmpeg-host" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-ffmpeg-host-${random_uuid.uuid.result}"
  public_key = tls_private_key.auto-gen-key-ffmpeg-host.public_key_openssh
}


resource "aws_security_group" "allow_ffmpeg-host" {
  name        = "ffmpeg-host-${random_uuid.uuid.result}"
  description = "Allow inbound/outbound traffic for ffmpeg-host"

  ingress {
    # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "ffmpeg-host"
  }
}

resource "aws_spot_instance_request" "ffmpeg-host" {
  ami = var.ami
  spot_type = "one-time"
  wait_for_fulfillment = true
  instance_type          = var.ami_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = ["${aws_security_group.allow_ffmpeg-host.id}", "sg-e980a381"]
  volume_tags = {
    Name = "ffmpeg Host - ${random_uuid.uuid.result}"
  }
  tags = {
    Uuid    = "${random_uuid.uuid.result}"
    Name    = "ffmpeg Host - ${random_uuid.uuid.result}"
    Transit = var.transit
  }
}

output "instance_ip" {
  value = "${join(",", list(
    aws_spot_instance_request.ffmpeg-host.public_ip
    )
  )}"
}

output "private_key" {
  value     = tls_private_key.auto-gen-key-ffmpeg-host.private_key_pem
  sensitive = true
}
