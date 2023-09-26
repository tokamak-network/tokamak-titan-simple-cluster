variable "service_name" {
  description = "ec2 service name"
}

variable "base_ami" {
  description = "base ami"
}

variable "instance_type" {
  description = "type"
  default = "t2.micro"
}

variable "key_name" {
  description = "key pair name"
}