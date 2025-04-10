variable "aws_region" {
  description = "AWS region to deploy EC2 instance"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "iam_user_name" {
  description = "Name of IAM user to create"
  type        = string
  default     = "ec2-user"
}

variable "key_pair" {
  description = "Key pair Name"
  type        = string
}

variable "instance_name" {
  description = "EC2 Instance name"
  type        = string
}
