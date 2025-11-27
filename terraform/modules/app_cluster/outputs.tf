output "ecr_url" { value = aws_ecr_repository.this.repository_url }
output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.this.name }
output "api_endpoint" { value = "https://api.${var.domain_name}" }
