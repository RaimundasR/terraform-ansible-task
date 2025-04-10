variable "key_name" {
  default = "microk8s-key"
}

variable "public_key_path" {
  default = "/home/pb/.ssh/microk8s-key.pub"
}

variable "ami" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
  default     = "ami-0a94c8e4ca2674d5a" # pvz. eu-west-2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}
