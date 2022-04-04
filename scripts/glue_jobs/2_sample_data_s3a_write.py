# Purpose:
# Generate sample data.
# Test write it to LakeFS using S3A endpoint.
# Test create Glue catalog entry over LakeFS using S3A endpoint.

import sys

sys.path.insert(0, "utils.zip")
import utils

from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

#####################################################
#####################################################
#####################################################

args = utils.get_args()

bucket = args.lakefs_s3_bucket
repo_name = args.lakefs_repo_name
branch_name = args.lakefs_branch_name

db = args.lakefs_catalog_db_name
table = "lakefs_s3a_table"

#####################################################
#####################################################
#####################################################

df = utils.create_sample_df()

# Write data to LakeFS table via S3A gateway
utils.configure_s3a(args)

output = f"s3a://{repo_name}/{branch_name}/data/sample_data_s3a/"
print(output)

df.write.partitionBy(["yyyy_mm_dd", "hh_mm"]).parquet(output)
df.createOrReplaceTempView("df")

# Create a catalog entry for this table

spark.sql(
    f"""
CREATE TABLE IF NOT EXISTS 
  {db}.{table}
USING PARQUET
PARTITIONED BY 
  (yyyy_mm_dd, hh_mm)
LOCATION 
  '{output}'
AS SELECT * FROM df
"""
)

# Update the catalog with the latest partitions
spark.sql(f"MSCK REPAIR TABLE {db}.{table}")
