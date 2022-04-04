# Purpose:
# Generate sample data.
# Test write it to S3 without using LakeFS at all.
# Test create Glue catalog entry over S3.

################################
# Debug / verify environment
import sys
import os

print(f"os.getcwd()={os.getcwd()}")
print(f"os.listdir('.')={os.listdir('.')}")

print(f"sys.path={sys.path}")
##################################

import sys

sys.path.insert(0, "utils.zip")
import utils

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame

from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()


glueContext = GlueContext(spark.sparkContext)


#####################################################
#####################################################
#####################################################

args = utils.get_args()

db = args.lakefs_catalog_db_name
bucket = args.lakefs_s3_bucket

df = utils.create_sample_df()

# Test: Can be viewed in Cloudwatch under output logs
# df.show()

# Write data to normal Glue table
spark.sql(
    f"""
CREATE DATABASE IF NOT EXISTS 
  {db}
"""
)

# Define catalog entry
table = "lakefs_s3_table"
spark.sql(
    f"""
CREATE TABLE IF NOT EXISTS 
  {db}.{table}
USING PARQUET
PARTITIONED BY 
  (yyyy_mm_dd, hh_mm)
LOCATION 
  's3://{bucket}/data/sample_data_s3/'
AS SELECT * FROM df
"""
)

# Write data using Glue API rather than Spark dataframe API, for fun
ddf = DynamicFrame.fromDF(df, glueContext, "df")

additionalOptions = {"enableUpdateCatalog": True}
additionalOptions["partitionKeys"] = ["yyyy_mm_dd", "hh_mm"]

sink = glueContext.write_dynamic_frame_from_catalog(
    frame=ddf,
    database=db,
    table_name=table,
    transformation_ctx="write_sink",
    additional_options=additionalOptions,
)

# Update the catalog with the latest partitions
spark.sql(f"MSCK REPAIR TABLE {db}.{table}")
