resource "tls_private_key" "simple_cluster_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "simple_cluster_keypair" {
  key_name = var.key_name
  public_key = tls_private_key.simple_cluster_key.public_key_openssh
}

resource "local_file" "simple_cluster_local_key" {
  filename = "./key/${var.key_name}.pem"
  content = tls_private_key.simple_cluster_key.private_key_pem
  file_permission = "0400"
}