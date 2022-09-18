
#vim output.tf 

#below output provide all the output declared in vpc module.

output "vpc_module_return" {
    value=module.vpc
}

output "alb-endpoint" {
    
    value = "http://${aws_lb.blog.dns_name}"
}
   
output "latest-ami-id"{
    value = data.aws_ami.amazon.image_id
}


output "security-group-id" {

value = "aws_security_group.sg.id"

}


