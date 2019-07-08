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

variable "cluster_name" {
    default = "ledivan-kubernetes"
}

variable "master_subnet_id" {
    default = "subnet-3a84ff5d"
}

variable "key" {
  type        = "string"
  default     = "docker.pem"
}