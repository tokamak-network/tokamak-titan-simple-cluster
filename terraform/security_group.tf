resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default"
  }
}

resource "aws_security_group" "simple_public" {
  name = "${var.service_name}-security-group"
  description = "Allow all traffic for test simple cluster"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
	ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
	ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.service_name}-security-group"
  }
}