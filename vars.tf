provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version  = ">=0.12.3, <=0.14.4"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instância a ser utilizado"
  default     = "t2.xlarge"
}

variable "ami" {
  type    = string
  default = "ami-0be3df9b8bb0a5f23"
}

variable "cluster_name" {
  default = "ledivan-kubernetes"
}

variable "master_subnet_id" {
  default = "subnet-0d57857f8a6ea19f2"
}

variable "key" {
  type    = string
  default = "docker.pem"
}