# module "vpc" {
#   source = "./vpc"

#   aws_region            = var.aws_region
#   vpc_name              = var.vpc_name
#   vpc_cidr_block        = var.vpc_cidr_block
#   count_public_subnets  = var.count_public_subnets
#   count_private_subnets = var.count_private_subnets
#   public_subnets_cidr   = var.public_subnets_cidr
#   private_subnets_cidr  = var.private_subnets_cidr
# }

data "aws_vpc" "default" {
  default = true
}

# Fetch the default subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "nextjs_lb_security_group" {
  name   = "nextjs_lb_security_group"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nextjs_ecs_security_group" {
  name   = "nextjs_ecs_security_group"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.nextjs_lb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "nextjs_alb" {
  name               = "nextjsalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nextjs_lb_security_group.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "nextjs_lb_tg" {
  name        = "nextjslbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "nextjs_lb_listener" {
  load_balancer_arn = aws_lb.nextjs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextjs_lb_tg.arn
  }
}

// ecs
resource "aws_ecs_cluster" "nextjs_cluster" {
  name = "nextjs-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "nextjs_task" {
  family                   = "nextjs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name  = "nextjs-container"
    image = "339712697129.dkr.ecr.ap-southeast-2.amazonaws.com/nextjs-docker:1.0.33"
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
      appProtocol   = "http"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/nextjs"
        awslogs-region        = "ap-southeast-2"
        awslogs-stream-prefix = "ecs"
        awslogs-create-group  = "true"
        mode                  = "non-blocking"
        max-buffer-size       = "25m"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "nextjs_service" {
  name            = "nextjs-service"
  cluster         = aws_ecs_cluster.nextjs_cluster.id
  task_definition = aws_ecs_task_definition.nextjs_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.nextjs_ecs_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nextjs_lb_tg.arn
    container_name   = "nextjs-container"
    container_port   = 3000
  }
}

