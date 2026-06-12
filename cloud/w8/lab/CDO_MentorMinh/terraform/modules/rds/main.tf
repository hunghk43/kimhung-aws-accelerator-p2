resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-db-subnets"
  })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-mysql-params"
  })
}

resource "aws_db_instance" "this" {
  identifier              = var.identifier
  engine                  = "mysql"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  port                    = 3306
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
  storage_type            = "gp3"
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  backup_retention_period = 7

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = var.security_group_ids

  tags = merge(var.tags, {
    Name = var.identifier
    Role = "mysql"
  })
}
