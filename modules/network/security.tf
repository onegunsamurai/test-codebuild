

module "http_80_security_group" {
  source              = "terraform-aws-modules/security-group/aws//modules/http-80"
  version             = "~> 4.0"
  vpc_id              = aws_vpc.main.id
  name                = "HTTP_80 security group"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}