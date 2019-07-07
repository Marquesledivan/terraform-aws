provider "aws" {
  region = "sa-east-1"
}

variable "instance_type" {
  type        = "string"
  description = "Tipo de instância a ser utilizado"
  default     = "t2.xlarge"
}

variable "ami" {
  type        = "string"
  default     = "ami-0be3df9b8bb0a5f23"
}

variable "vpc_security_group_ids"{
  default    = ["sg-017f224a4b08c2d14"]

}

variable "key" {
  type        = "string"
  default     = "docker.pem"
}