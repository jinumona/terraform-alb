
#vim main.tf

# security group updated
module "vpc" {
    
  source = "/home/ec2-user/t-10-lb/vpc-module/"
  vpc_cidr = var.project_vpc_cidr
  project  = var.project_name
  env      = var.project_env
}


resource "aws_key_pair" "key" {
    
    key_name   = "${var.project_name}-${var.project_env}"
    public_key = file("localkey.pub")
    tags = {
      
       Name = "${var.project_name}-${var.project_env}"
       project = var.project_name
       env = var.project_env
    }
}

#creating security group 
resource "aws_security_group" "sg" {
      
  name        = "webserver-${var.project_name}-${var.project_env}"
  description = "Allow 80,443,22 traffic"
  vpc_id      = module.vpc.vpc_id
  
    ingress {
   
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
   
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
   
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


    

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
      
       Name = "webserver-${var.project_name}-${var.project_env}"
       project = var.project_name
       env = var.project_env
  }
    
}



#creating alb 

resource "aws_lb" "blog" {
 name_prefix              = "blog-"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [module.vpc.public1_subnet_id , module.vpc.public2_subnet_id]
enable_cross_zone_load_balancing = true

 tags = {
      
       Name = "webserver-${var.project_name}-${var.project_env}"
       project = var.project_name
       env = var.project_env
  }
}

#creating target group for alb 

resource "aws_lb_target_group" "blog" {
  name_prefix   = "blog-"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    port                = 80
   path = "/"
    interval            = 30
  }

}


#alb listenrs 
#attaching alb with target group 

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.blog.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.amazon_issued.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog.arn
  }
}

#redirectioon alb listener 
#attaching alb with target group 

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = aws_lb.blog.arn
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

# route 53

#creating A record for blog 

resource "aws_route53_record" "blog-A" {
  zone_id = data.aws_route53_zone.main-domain.zone_id
  name    = var.sub-domain
  type    = "A"

 alias {
    name                   = aws_lb.blog.dns_name
    zone_id                = aws_lb.blog.zone_id
    evaluate_target_health = true
  }
}





#creating launch configuration
resource "aws_launch_configuration" "myapp" {
  
  name_prefix       = "myapp-"
  image_id          = data.aws_ami.amazon.image_id
  instance_type     = var.instance_type
  key_name          = aws_key_pair.key.id
  security_groups   = [ aws_security_group.sg.id ]
  user_data     = file("setup.sh")
  
  lifecycle {
    create_before_destroy = true
  }

}

#create autoscaling group 
#pointing the instance id to target group 

resource "aws_autoscaling_group" "myapp" {

  name_prefix             =  "myapp-"
  launch_configuration    =  aws_launch_configuration.myapp.name
  vpc_zone_identifier     =  [module.vpc.public1_subnet_id , module.vpc.public2_subnet_id]
                                                               
  health_check_type       = "EC2"
  min_size                = "2"
  max_size                = "2"
  desired_capacity        = "2"
  wait_for_elb_capacity   = "2"
  target_group_arns          = [aws_lb_target_group.blog.id]

 lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = var.project_name
    propagate_at_launch = true
  }

}


# s3 backend for tfstate file

terraform {
  backend "s3" {
    bucket = "terrafrom.inenso.in"
    key    = "terraform/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraformlock"
  }
}


