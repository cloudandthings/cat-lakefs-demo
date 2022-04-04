## General
variable "aws_account_id" {
  type        = string
  description = "Needed for Guards to ensure code is being deployed to the correct account"
}

variable "region" {
  type        = string
  description = "The default region for the application / deployment"
}

variable "naming_prefix" {
  # TODO descript
  type = string
}

variable "mandatory_tags" {
  type        = map(string)
  description = "Default tags added to all resources, this will be added to the provider"
}

## Network configuration

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

## LakeFS RDS configuration
variable "rds_admin_user" {
  type    = string
  default = "lakefs_admin"
}

variable "rds_admin_password" {
  type      = string
  sensitive = true
}

variable "rds_snapshot_id" {
  description = "Optional RDS Snapshot ID to restore from"
  type        = string
  default     = ""
}

## LakeFS Server EC2 configuration
variable "lakefs_encrypt_secret_key" {
  description = "LakeFS encryption key. Changing this will make any existing RDS data eg snapshots, unusable."
  sensitive   = true
}

variable "ssh_authorized_keys" {
  type = list(string)
}

## LakeFS application configuration
variable "lakefs_s3_bucket" {
  description = "LakeFS S3 bucket name, will be created and force-destroyed (including ALL data) by this TF environment."
  type        = string
}

variable "lakefs_repo_name" {
  type    = string
  default = "main-repo"
}

variable "lakefs_branch_name" {
  type    = string
  default = "main"
}

variable "hadoop_lakefs_assembly_jar_bucket" {
  description = "Hadoop LakeFS Assembly jar bucket on S3"
  type        = string
}

variable "hadoop_lakefs_assembly_jar_object_key" {
  description = "Hadoop LakeFS Assembly jar object key on S3"
  type        = string
  default     = "lakefs/assets/hadoop-lakefs-assembly-0.1.6.jar"
}

variable "s3_region_endpoint" {
  description = "S3 region endpoint, see https://docs.lakefs.io/integrations/spark.html#configuration-1"
  type        = string
  default     = "use-default"
}

variable "lakefs_iam_user" {
  type    = string
  default = "lakefs"
}