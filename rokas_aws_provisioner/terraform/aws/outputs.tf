output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "instance_profile" {
  description = "The IAM instance profile associated with the EC2 instance"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}
