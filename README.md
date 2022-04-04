# terraform-aws-infrastructure-template

# Overview

TODO make this shine

# Medium write-up

See our write-up on Medium, here:
TODO

# LakeFS demo

Reference: https://lakefs.io/

# Configure Terraform

1. Configure backend.
Copy `backend_example.tf` to `backend.tf` and update it.

2. Configure variables,
Copy `terraform_example.tfvars` to `terraform.tfvars` and update it.

## Configuring LakeFS / RDS

Note that we can run in one of 2 possible modes:
1. A new RDS is created from scratch. 

Do this at least the first time you use this repo.
An admin user + credentials must be created initially via a manual process.
This might be possible via the LakeFS API and a compatible client - untested. 

These credentials need to be used in various places, and each time the RDS is destroyed the credentials will need to be changed wherever they are used.

2. A new RDS is created out of a snapshot. 

This is optional, for convenience
The admin user+credentials from the prior RDS snapshot are still applicable. We dont need to update everything which was configured to use the existing credentials.

# Create LakeFS infrastructure

- `terraform apply`

Terraform will display the public IP address of the LakeFS Server.

Remember to run `terraform destroy` later once you are done.

The LakeFS web UI will be accessible via the server EC2 instance public IP, which is output by Terraform. Connect on port 8000 using a web browser.

## Set up LakeFS admin user

This step is only necessary when a new RDS instance is created.
- Access lakefs via the LakeFS web UI, and you should be routed to the `setup` page.
- Create an admin user on the LakeFS UI.
- Download the LakeFS admin user credentials.

At this point it is recommended to take an RDS snapshot, for example `lakefs-init`. This means the credentials will still be valid to connect to LakeFS even on new infrastructure.

## Create a LakeFS repo

Use the UI to create a repo and point it to a new bucket, or an existing bucket with a new prefix.

Recommended settings:
```
Bucket = s3://<LAKEFS BUCKET>/lakefs/
Repo = main-repo
Branch = main
```

TODO:
Could be done using a lakefs client as follows:

```
lakectl repo create lakefs://source-data s3://treeverse-demo-lakefs-storage-production/user_m1eo6o342cajzqaa/source-data
```

Or probably using the API.

Create another RDS snapshot, for example `lakefs-init-with-repo`

## Configure snapshot (optional)

With the RDS snapshots, we can update `terraform.tfvars` with the following: 
- RDS snapshot ID: `rds_snapshot_id`

If we run `terraform destroy` to trash our environment, then next time LakeFS will be recreated with the RDS snapshot specified - preserving credentials and optionally the repo also. 

Finally we can re-run `terraform apply` to ensure changes take effect in any dependent resources.

## Set up IAM user

An IAM user credential is used, only when accessing S3 when Glue reads/writes directly to S3 using the LakeFS filesystem format. 

Manually create an IAM user called `lakefs`, and attach a policy to the user which allows s3:* to the lakefs bucket.

## Store secret in AWS Secrets Manager

Create a secret in AWS Secrets Manager called `lakefs` and populate the following key-value pairs:

| Key | Value |
| -- | -- |
| iam-user-access-key| IAM user access key |
| iam-user-secret-key | IAM user secret key |
| lakefs-access-key | LakeFS admin user access key |
| lakefs-secret-key | LakeFS admin user secret key |

The LakeFS Glue jobs illustrate 2 different modes of accessing LakeFS.

If LakeFS uses its built-in S3 gateway then data is sent via the gateway (i.e via the LakeFS server) and therefore no IAM permission is needed. However the EC2 instance attached IAM role will then need S3 permissions.

## Set up lakefs client

- TODO - not yet implemented


# Use LakeFS to ingest data

## Ingesting data with the LakeFS ingest tool

TODO - not tested.
Ingesting sample data from https://registry.opendata.aws/speedtest-global-performance/
```
lakectl ingest \
  --from s3://ookla-open-data/parquet/performance/type=mobile/ \
  --to lakefs://source-data/main/performance/type=mobile/

lakectl commit lakefs://source-data/main -m 'source data loaded'
```

TODO - Glue catalogue

After the data has been ingested and catalogued, we can consider setting up `lakectl metastore` to also use the Glue catalog.

## Ingesting data using Spark

Spark can be used to read and write data to LakeFS.

See the scripts directory for some sample Glue jobs.

The Glue jobs each test 2 methods of accessing data; firstly via the Spark dataframe API to access data on the underlying storage (excluding catalog) and secondly using the Glue catalog to access the data.

In addition, the multiple Glue jobs fulfil different functions.
See the comment at the top of each one for details.


# Using LakeFS for other stuff

# Known issues

- Various TODOs in the code.

- This demo environment is insecure for various reasons including those listed below. Do not put any sensitive data on this LakeFS environment.
- - Postgres master user/password is used in LakeFS configuration file instead of a lakefs-specific user. This could be fixed perhaps with the Terraform PostgreSQL provider.
- - The EC2 instance is open to the world so that Glue can talk to it. We could in future look at Glue endpoints in the VPC.
- - The Glue user has administrator user access

- Perhaps a Terraform HTTM provider could be used to create the LakeFS admin user and store the credentials automatically / via API.

- The Objects view by default displays objects in the current workspace, which includes uncommitted objects. You can switch to see objects at the last commit, but this is unintuitive.

# Nice to haves

- A LakeFS Terraform provider might be be nice, perhaps for creating the LakeFS admin user credentials and storing them in AWS Secrets Manager automatically. There might be security issues with this though - would the credentials be stored in the TF state?
