output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

#output "iam_user" {
#  value = aws_iam_user.user.name
#}

output "vpc_id" {
  value = aws_vpc.main.id
}
