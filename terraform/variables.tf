variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  default = "vpc-08a45f9d0ec6c1113"
}

variable "subnet_id" {
  default = "subnet-01cd458886cce3068"
}

variable "app_security_group_id" {
  default = "sg-025413303c2617561"
}

variable "ami_id" {
  default = "ami-0d97d7f07b25dd693"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "key_name" {
  default = "linux"
}
