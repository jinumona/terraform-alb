#vim variables.tf 

variable "region" {
    
  default = "ap-south-1"
}

variable "project_name" {
    
  default = "zomato"
}


variable "project_vpc_cidr" {
    
  default = "172.25.0.0/16"
}

variable "project_env" {
    
  default = "prod"
}
variable "instance_type" {
  default = "t2.micro"
}

variable "main-domain" {
    default="inenso.in"
}

variable "sub-domain" {
default= "blog.inenso.in"

}

