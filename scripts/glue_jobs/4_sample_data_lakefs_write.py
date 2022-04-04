# Purpose:
# Generate sample data.
# Test write it to LakeFS using LakeFS filesystem (direct to S3).
# Test create Glue catalog entry over LakeFS using LakeFS endpoint.

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
table = "lakefs_table"

#####################################################
#####################################################
#####################################################

df = utils.create_sample_df()

# Write data to LakeFS table via LakeFS filesystem on S3
utils.configure_lakefs(args)

# Write data using dataframe API
output = f"lakefs://{repo_name}/{branch_name}/data/sample_data_lakefs/"
print(output)
df.write.partitionBy(["yyyy_mm_dd", "hh_mm"]).parquet(output)
df.createOrReplaceTempView("df")

# Write data using the Glue catalog
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

spark.sql(f"MSCK REPAIR TABLE {db}.{table}")
