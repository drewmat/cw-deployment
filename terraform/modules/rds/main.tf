resource "aws_security_group" "this" {
  name_prefix = "${var.identifier}-"
  description = "Postgres access from EKS nodes only"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

# count (not for_each): the SG IDs are only known after apply on a first run, but
# the number of entries in the list is known at plan time.
resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Postgres from EKS nodes"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = var.identifier

  engine               = "postgres"
  engine_version       = var.engine_version
  family               = var.family
  major_engine_version = var.engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 5
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  port     = 5432

  # RDS creates and rotates the master password in Secrets Manager; it never
  # appears in Terraform config or state. External Secrets syncs it into K8s.
  manage_master_user_password = true

  create_db_subnet_group = false
  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = 7
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  performance_insights_enabled = true
}
