# Purpose:
# Test read data from LakeFS using S3A endpoint.
# Test read data from LakeFS using S3A endpoint and using Glue catalog.

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

utils.configure_s3a(args)

# Read data from LakeFS table
input = f"s3a://{repo_name}/{branch_name}/data/sample_data_s3a/"
print(input)

# Read data in using DF API
df_read = spark.read.option("basePath", input).parquet(input)
df_read_count = df_read.count()

if df_read_count == 0:
    raise Exception("We expected to find some data to read")

print(f"df_read_count={df_read_count}")

# Read data in using catalog
catalog_count = spark.sql(
    f"""
SELECT * FROM {db}.{table}
"""
).count()

if catalog_count != df_read_count:
    raise Exception("We expected the catalog table count to match the df API count")
