# TODO structure
/*
########################################
# An example of configuring your Terraform variables. 
# Copy/rename to terraform.tfvars
# Update and uncomment this file
########################################

// Default vars
region = "eu-west-1"

aws_account_id = "11223344556"

mandatory_tags = {
  "key" = "value"
}

naming_prefix = "my-unique-naming-prefix"

// LakeFS vars
vpc_id = "vpc-123"

subnet_ids = [
  "subnet-0a123"
  ,"subnet-0a456"
  ,"subnet-0a789"
]

rds_admin_password = "some_password"

# If set to empty string, new RDS will be created and used
# Otherwise, RDS will be created and used from snapshot
rds_snapshot_id = ""

# Admin creds set up but no repos
# rds_snapshot_id = "lakefs-init"

# Admin creds and repo=main-repo, branch=main, storage=my_bucket/lakefs
# rds_snapshot_id = "lakefs-init-with-repo"

# Note that changing this will make the RDS snapshot unusable.
lakefs_encrypt_secret_key = "some_random_encryption_secret"

hadoop_lakefs_assembly_jar_bucket = "my-state-bucket"

s3_region_endpoint = "https://s3.eu-west-1.amazonaws.com"

ssh_authorized_keys = [
  "MYSSHPUBKEYA555AAA5"
]
# OR
ec2_key_pair_name = "my-key-pair"

*/
