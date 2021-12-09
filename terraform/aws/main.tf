terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
# For security reasons, all AWS credentials 
# have been exported as envriomental vaialbes 
# export AWS_ACCESS_KEY_ID=xxxxxxxx
# export AWS_SECRET_ACCESS_KEY=xxxxxxx
# export AWS_DEFAULT_REGION="us-west-x"
provider "aws" {}

# Create ECR repository to push docker image
resource "aws_ecr_repository" "ledn-repository" {
  name                 = "ledn-nginx"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Deploy ESC Cluster
resource "aws_ecs_cluster" "ledn-cluster" {
  name = "ledn-cluster"
}

# Create ECS Task
resource "aws_ecs_task_definition" "ledn-task" {
  family                   = "ledn-nginx"
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "ledn-nginx",
      "image": "l858270123827.dkr.ecr.us-west-2.amazonaws.com/ledn-nginx",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 256,
      "cpu": 128
    }
  ]
  TASK_DEFINITION
  network_mode             = "awsvpc"
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

# Create role to execute task 
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-west-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-west-2b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-west-2c"
}

resource "aws_ecs_service" "ledn-service" {
  name            = "ledn-service"
  cluster         = "${aws_ecs_cluster.ledn-cluster.id}"
  task_definition = "${aws_ecs_task_definition.ledn-task.arn}"
  launch_type     = "EC2"
  desired_count   = 1
  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    # assign_public_ip = true
    }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.ledn-task.family}"
    container_port   = 80
  }
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_lb" "application_load_balancer" {
  name               = "ledn-lb-tf"
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.application_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}


output "myOutput" {
   value = "aws_ecs_task_definition"
}