##################################
# Security Groups
##################################

resource "aws_security_group" "sg_server" {
  name   = "Allow EC2 access"
  vpc_id = var.vpc_id
}

# Allow my IP to SSH
resource "aws_security_group_rule" "allow_my_ip_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.sg_server.id
}

# Allow ingress to UI
resource "aws_security_group_rule" "allow_my_ip_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.sg_server.id
}

# Glue
# TODO we aren't in a VPC so I had to allow 0/0
resource "aws_security_group_rule" "allow_glue_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_server.id
}

resource "aws_security_group_rule" "allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_server.id
}

##################################
# AMI
##################################

data "aws_ami" "amzn2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
  #owners = ["137112412989"] # Amazon
  #image_owner_alias = "amazon"
}

##################################
# Server Instance
##################################

# Lookup the RDS as it could have been created from a snapshot
data "aws_db_instance" "lakefs" {
  db_instance_identifier = local.rds_identifier
  depends_on = [
    aws_db_instance.lakefs,
    aws_db_instance.lakefs_from_snapshot,
  ]
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.sg_server.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.lakefs_server.name

  user_data = templatefile(
    "scripts/server-cloud-init.yaml",
    {
      # TODO using the rds admin user for convenience
      database_connection_string = format(
        "postgresql://%s:%s@%s/%s",
        var.rds_admin_user,
        var.rds_admin_password,
        data.aws_db_instance.lakefs.endpoint,
        data.aws_db_instance.lakefs.db_name
      )
      encrypt_secret_key  = var.lakefs_encrypt_secret_key
      region              = var.region
      account_id          = var.aws_account_id
      ssh_authorized_keys = var.ssh_authorized_keys
  })
  # Rather add your public SSH keys to scripts/server-cloud-init.yaml
  # key_name = "some_ec2_ssh_key_pair_name"
  tags = {
    Name = "lakefs-server"
  }
}
