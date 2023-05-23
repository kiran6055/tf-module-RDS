# creating subnetgroup for RDS
resource "aws_db_subnet_group" "default" {
  name       = "${var.env}-rds-subnet-group"
  subnet_ids = var.subnet_ids
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rds-subnet-group" }
  )
}

# creating security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.env}-rds-security-group"
  description = "${var.env}-rds-security-group"
  vpc_id      = var.vpc_id
  ingress {
    description = "RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allow_cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rds-security-group" }
  )
}

# creating RDS cluster
resource "aws_rds_cluster" "rds" {
  cluster_identifier     = "${var.env}-rds"
  engine                 = var.engine
  engine_version         = var.engine_version
  master_username        = data.aws_ssm_parameter.DB_ADMIN_USER.value
  master_password        = data.aws_ssm_parameter.DB_ADMIN_PASS.value
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  storage_encrypted      = true
  kms_key_id             = data.aws_kms_key.key.arn
  skip_final_snapshot    = true

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rds" }
  )
}

# creating nodes(instances) in rds cluster
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.number_of_instances
  identifier         = "${var.env}-rds-${count.index+1}"
  cluster_identifier = aws_rds_cluster.rds.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.rds.engine
  engine_version     = aws_rds_cluster.rds.engine_version
}


# creating aws ssm parameter user for mysql rds for running and adding schemaload which is given in app main

resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "${var.env}.rds.Endpoint"
  type  = "String"
  value = aws_rds_cluster.rds.endpoint
}
