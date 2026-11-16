variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "Instance type for the Jenkins EC2 instance"
  default     = "m7i-flex.large" 
} 

variable "my_enviroment" {
  description = "Environment tag for the resources"
  default     = "dev"
}