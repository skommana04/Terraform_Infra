provider "aws" {
  region = var.region
}

# create vpc
module "vpc" {
  source                  = "./modules/vpc"
  project_name            = var.project_namez
  vpc_cidr                = var.vpc_cidr_block
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  ami                     = var.ami
  key_name                = var.key_name
  instance_type           = var.instance_type
  ec2_security_group_id   = module.security_group.ec2_security_group_id
}




# create security group
module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
}
