
#vim datasource.tf 

#datasource for ami ids 

data "aws_ami" "amazon" {
  
  owners        = ["amazon"]
  most_recent  = true
    

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#datasource for acm certificate

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.main-domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}


#datasource for getting zone id of main domain for the creation of ns records for the sub hosted zone

data "aws_route53_zone" "main-domain" {
  name         = var.main-domain
}
