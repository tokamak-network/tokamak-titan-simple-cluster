variable "service_name" {
  description = "ec2 service name"
}

variable "base_ami" {
  description = "base ami"
  default = "ami-0c9c942bd7bf113a2"
}

variable "instance_type" {
  description = "type"
  default = "t2.medium"
}

variable "key_name" {
  description = "key pair name"
}

variable "git_user" {
  description = "git user name"
}

variable "git_email" {
  description = "git user email"
}