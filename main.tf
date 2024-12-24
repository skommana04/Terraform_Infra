provider "aws" {
  region = var.region
}

# create vpc
module "vpc" {
  source                  = "modules/vpc"
  project_name            = var.project_namez
  vpc_cidr                = var.vpc_cidr_block
}


