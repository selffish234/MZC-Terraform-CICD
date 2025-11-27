provider "aws" { region = "eu-west-1" }
provider "aws" { alias = "virginia"; region = "us-east-1" }

locals {
  prefix           = "joon-stage"
  domain_name      = "selffish234.cloud"
  full_domain_name = "stage.selffish234.cloud"
}

module "network" {
  source          = "../../modules/network"
  prefix          = local.prefix
  vpc_cidr        = "10.1.0.0/16"
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.10.0/24", "10.1.11.0/24"]
  azs             = ["eu-west-1a", "eu-west-1c"]
}
module "app_cluster" {
  source             = "../../modules/app_cluster"
  prefix             = local.prefix
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  domain_name        = local.domain_name
  container_port     = 3000
}
module "frontend" {
  source           = "../../modules/static_site"
  prefix           = local.prefix
  domain_name      = local.domain_name
  full_domain_name = local.full_domain_name
  providers        = { aws.virginia = aws.virginia }
}
output "ecr_repo_url" { value = module.app_cluster.ecr_url }
output "api_endpoint" { value = module.app_cluster.api_endpoint }
output "cloudfront_id" { value = module.frontend.cloudfront_id }
output "s3_bucket" { value = module.frontend.s3_bucket }
