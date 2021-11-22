resource "aws_security_group" "allow_80" {
  name        = "allow_http"
  description = "Allow HTTP 80 incoming traffic"
  vpc_id      = var.vpc_id

  ingress {
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = ["0.0.0.0/0"]
    }
  

  egress {

      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_HTTP"
  }
}