terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-northeast-2"
}

resource "aws_instance" "simple_cluster_server" {
  ami           = var.base_ami
  instance_type = var.instance_type
  key_name = aws_key_pair.simple_cluster_keypair.key_name
  vpc_security_group_ids = [aws_security_group.simple_public.id]

  root_block_device {
    volume_size = "20"
  }

  connection {
    type = "ssh"
	  host = self.public_ip
	  user = "ubuntu"
	  private_key = file("./key/${var.key_name}.pem")
  }

  provisioner "file" {
    source = "../../tokamak-titan-simple-cluster"
    destination = "/home/ubuntu"
  }

  provisioner "file" {
    source = "provision_script.sh"
	  destination = "/tmp/provision_script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_script.sh",
	    "/tmp/provision_script.sh ${var.git_user} ${var.git_email} ${var.minikube_cpus} ${var.minikube_memory}",
	  ]
  }

  tags = {
    Name = var.service_name
  }
}