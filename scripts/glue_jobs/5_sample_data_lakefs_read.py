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

# Write data to LakeFS table
utils.configure_lakefs(args)

input = f"lakefs://{repo_name}/{branch_name}/data/sample_data_lakefs/"
print(input)

# Read from dataframe API
df_read = spark.read.option("basePath", input).parquet(input)
df_read_count = df_read.count()

if df_read_count == 0:
    raise Exception("We expected to find some data to read")

print(f"df_read_count={df_read_count}")

# Read from catalog
catalog_count = spark.sql(
    f"""
SELECT * FROM {db}.{table}
"""
).count()

if catalog_count != df_read_count:
    raise Exception("We expected the catalog table count to match the df API count")
