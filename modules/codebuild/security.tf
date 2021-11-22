resource "aws_security_group" "codebuild_security" {
  name        = "codebuild-sec-group"
  description = "Codebuild Sec Group"
  vpc_id      = var.vpc_id


  dynamic "ingress" {
      for_each = ["80", "22", "443"]
      content {
        protocol         = "tcp"
        from_port        = ingress.value
        to_port          = ingress.value
        cidr_blocks      = ["0.0.0.0/0"]
      }
  }
  

  egress {

      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CodeBuild Security Group"
  }
}