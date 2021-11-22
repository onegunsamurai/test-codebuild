resource "aws_ecr_repository" "default" {
  name = "${var.env}-ecr-master"
}

