output "devops_instance_id" {
  value = aws_instance.devops.id
}

output "devops_public_ip" {
  value = aws_instance.devops.public_ip
}

output "devops_private_ip" {
  value = aws_instance.devops.private_ip
}

output "ecr_repository_urls" {
  value = [
    aws_ecr_repository.user_service.repository_url,
    aws_ecr_repository.product_service.repository_url,
    aws_ecr_repository.order_service.repository_url
  ]
}
