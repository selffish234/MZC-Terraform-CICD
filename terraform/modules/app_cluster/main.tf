resource "aws_security_group" "alb" {
  name   = "${var.prefix}-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.prefix}-alb-sg" }
}
resource "aws_security_group" "ecs" {
  name   = "${var.prefix}-ecs-sg"
  vpc_id = var.vpc_id
  ingress {
    protocol = "tcp"
    from_port = var.container_port
    to_port = var.container_port
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.prefix}-ecs-sg" }
}
resource "aws_lb" "this" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags = { Name = "${var.prefix}-alb" }
}
resource "aws_lb_target_group" "this" {
  name        = "${var.prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/"
    matcher = "200"
  }
  tags = { Name = "${var.prefix}-tg" }
}
data "aws_route53_zone" "this" {
  name = var.domain_name
}
# 도메인 이름 생성 (dev, stage는 subdomain 사용, prod는 www 사용 등)
# 이를 위해 prefix가 prod가 아니면 subdomain 생성 로직이 필요하나,
# 간단하게 여기서는 변수로 받은 domain_name을 그대로 사용 (외부에서 조합해서 주입)
resource "aws_acm_certificate" "api" {
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.prefix}-api-cert" }
}
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => dvo
  }
  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = data.aws_route53_zone.this.zone_id
}
resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.api.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
resource "aws_ecr_repository" "this" {
  name         = "${var.prefix}-repo"
  force_delete = true
  tags = { Name = "${var.prefix}-repo" }
}
resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-cluster"
  tags = { Name = "${var.prefix}-cluster" }
}
resource "aws_iam_role" "execution" {
  name = "${var.prefix}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions    = jsonencode([{
    name      = "app"
    image     = aws_ecr_repository.this.repository_url
    essential = true
    portMappings = [{ containerPort = var.container_port, hostPort = var.container_port }]
  }])
  tags = { Name = "${var.prefix}-task" }
}
resource "aws_ecs_service" "this" {
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = var.container_port
  }
  depends_on = [aws_lb_listener.https]
  tags = { Name = "${var.prefix}-service" }
}
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
