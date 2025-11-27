variable "prefix" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "domain_name" {}
variable "container_port" { default = 3000 }
