
##################################
# Configuration
##################################
locals {
  rds_instance_class = "db.t3.small"
  rds_db_name        = "lakefs_db"
  rds_identifier     = "lakefs-rds" # Name in the console
}

##################################
# Subnet group
##################################
resource "aws_db_subnet_group" "lakefs" {
  name       = "lakefs"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "lakefs"
  }
}

##################################
# Security Groups
##################################


resource "aws_security_group" "sg_rds" {
  name   = "Allow RDS access"
  vpc_id = var.vpc_id
}

# Allow my IP to psql
resource "aws_security_group_rule" "allow_my_ip_5432" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.sg_rds.id
}

# Allow EC2 in
resource "aws_security_group_rule" "allow_lakefs_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_rds.id
  source_security_group_id = aws_security_group.sg_server.id
}

locals {
  rds_security_groups = [
    # Just in case we need to add more
    aws_security_group.sg_rds.id
  ]
}

##################################
# RDS instance
##################################

resource "time_sleep" "wait_30_seconds" {
  create_duration  = "30s"
  destroy_duration = "30s"
}

resource "aws_db_instance" "lakefs" {
  count = var.rds_snapshot_id == "" ? 1 : 0

  # !!!!!!!!!!!!!!!!!!!!!!! NB !!!!!!!!!!!!!!!!!!!!!!!!!
  # Keep below parameters in sync on both aws_db_instance resources

  identifier = local.rds_identifier
  engine     = "postgres"

  instance_class = local.rds_instance_class

  db_subnet_group_name = aws_db_subnet_group.lakefs.name

  allocated_storage     = 20
  max_allocated_storage = 40
  storage_encrypted     = true

  name = local.rds_db_name # deprecated but still in provider v3x
  # db_name               = "lakefs_db"

  username = var.rds_admin_user
  password = var.rds_admin_password

  vpc_security_group_ids = local.rds_security_groups
  #publicly_accessible = true
  /*
  Error: Error modifying DB Instance lakefs-rds: InvalidVPCNetworkStateFault: Cannot create a publicly accessible DBInstance.  
  The specified VPC does not support DNS resolution, DNS hostnames, or both. Update the VPC and then try again
  */

  apply_immediately   = true
  skip_final_snapshot = true

  tags = {
    Name = "lakefs"
  }
  depends_on = [
    # AWS Provider minor bug.
    # Instance already exists error when RDS is destroyed and recreated immediately with same instance ID.
    time_sleep.wait_30_seconds
  ]
}

data "aws_db_snapshot" "latest_snapshot" {
  count = var.rds_snapshot_id == "" ? 0 : 1

  db_snapshot_identifier = var.rds_snapshot_id
  most_recent            = true
}

# Use the latest snapshot to create an RDS instance.
resource "aws_db_instance" "lakefs_from_snapshot" {
  count               = var.rds_snapshot_id == "" ? 0 : 1
  snapshot_identifier = data.aws_db_snapshot.latest_snapshot[0].id

  # !!!!!!!!!!!!!!!!!!!!!!! NB !!!!!!!!!!!!!!!!!!!!!!!!!
  # Keep below parameters in sync on both aws_db_instance resources
  identifier = local.rds_identifier
  engine     = "postgres"

  instance_class = local.rds_instance_class

  db_subnet_group_name = aws_db_subnet_group.lakefs.name

  allocated_storage     = 20
  max_allocated_storage = 40
  storage_encrypted     = true

  name = local.rds_db_name # deprecated but still in provider v3x
  # db_name               = "lakefs_db"

  username = var.rds_admin_user
  password = var.rds_admin_password

  vpc_security_group_ids = local.rds_security_groups

  apply_immediately   = true
  skip_final_snapshot = true

  tags = {
    Name = "lakefs"
  }
  depends_on = [
    # AWS Provider minor bug.
    # Instance already exists error when RDS is destroyed and recreated immediately with same instance ID.
    time_sleep.wait_30_seconds
  ]
}