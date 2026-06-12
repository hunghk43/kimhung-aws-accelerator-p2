data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = merge(var.tags, {
    Project = var.project_name
    Managed = "terraform"
    Env     = "dev"
  })
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix   = var.project_name
  vpc_id        = module.vpc.vpc_id
  admin_cidr    = var.admin_cidr
  app_port      = var.app_port
  database_port = 3306
  tags          = local.common_tags
}

module "storage" {
  source = "../../modules/storage"

  bucket_name = var.s3_assets_bucket_name
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier         = var.project_name
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.rds_security_group_id]
  db_name            = var.mysql_db_name
  username           = var.mysql_master_username
  password           = var.mysql_master_password
  engine_version     = var.mysql_engine_version
  instance_class     = var.mysql_instance_class
  allocated_storage  = var.mysql_allocated_storage
  tags               = local.common_tags
}

module "ec2" {
  source = "../../modules/ec2"

  name_prefix        = var.project_name
  ami_id             = data.aws_ami.amazon_linux_2023.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.ec2_security_group_id]
  key_name           = var.key_name

  app_name          = var.project_name
  app_port          = var.app_port
  mysql_host        = module.rds.endpoint
  mysql_port        = module.rds.port
  mysql_database    = var.mysql_db_name
  mysql_user        = var.mysql_master_username
  mysql_password    = var.mysql_master_password
  s3_bucket_name    = module.storage.bucket_name
  source_bundle_url = var.source_bundle_url
  tags              = local.common_tags
}

module "cdn" {
  source = "../../modules/cdn"

  name_prefix    = var.project_name
  ec2_public_dns = module.ec2.public_dns
  app_port       = var.app_port
  tags           = local.common_tags
}
