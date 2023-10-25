output "instance_id" {
    description = "ID of the EC2 instance"
    value       = aws_instance.simple_cluster_server.id
}

output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"
    value       = aws_instance.simple_cluster_server.public_ip
}

output "connect_instance" {
    description = "connect ec2 instance command"
    value       = "ssh -i ${abspath(path.root)}/key/${var.key_name}.pem ubuntu@${aws_instance.simple_cluster_server.public_ip}"
}