import argparse
import random
import string
import json
from datetime import datetime

import boto3

from pyspark.sql import SparkSession

#######################################################################
#######################################################################
#######################################################################


def get_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--lakefs-s3-bucket", required=True)
    parser.add_argument("--lakefs-repo-name", required=True)
    parser.add_argument("--lakefs-branch-name", required=True)
    parser.add_argument("--lakefs-catalog-db-name", required=True)

    parser.add_argument("--lakefs-url", required=True)
    parser.add_argument("--lakefs-api-endpoint", required=True)

    parser.add_argument("--region", default=None)
    parser.add_argument("--s3-region-endpoint", default=None)

    # parser.parse_args()
    # Glue sends a bunch of other Args we can ignore.
    # Python2 returns a tuple
    args, options = parser.parse_known_args()
    # Visible in Cloudwatch. TODO dont send anything secret in the above args :)
    print(f"args={args}")
    print(f"options={options}")
    return args


#######################################################################
#######################################################################
#######################################################################

charset = string.ascii_lowercase


def get_random_string(length):
    result_str = "".join(random.choice(charset) for i in range(length))
    return result_str


now_datetime = datetime.now()


def create_sample_data(num_rows):
    data = []
    for i in range(num_rows):
        d = {
            "yyyy_mm_dd": now_datetime.strftime("%Y-%m-%d"),
            "hh_mm": now_datetime.strftime("%H-%M"),
            "i": i,
            "datetime_now": now_datetime,
            "random_text": get_random_string(5),
            "random_float": round(random.uniform(0.01, 10000.01), 2),
        }
        data.append(d)
    return data


def create_sample_df():
    data = create_sample_data(100)

    spark = SparkSession.builder.getOrCreate()
    df = spark.createDataFrame(data)
    df.createOrReplaceTempView("df")
    return df


#######################################################################
#######################################################################
#######################################################################


def get_secret(args):

    secret_name = "lakefs"
    region_name = args.region

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    secret = get_secret_value_response["SecretString"]
    return json.loads(secret)


#######################################################################
#######################################################################
#######################################################################


def configure_s3a(args):
    spark = SparkSession.builder.getOrCreate()
    secret = get_secret(args)
    # Could be made bucket-specific.
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.access.key", secret["lakefs-access-key"]
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.secret.key", secret["lakefs-secret-key"]
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.endpoint", args.lakefs_url
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.path.style.access", "true"
    )


def configure_lakefs(args):
    spark = SparkSession.builder.getOrCreate()
    secret = get_secret(args)

    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.access.key", secret["iam-user-access-key"]
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.s3a.secret.key", secret["iam-user-secret-key"]
    )

    # If not using us-east-1 then change from the default endpoint.
    s3_region_endpoint = args.s3_region_endpoint
    if s3_region_endpoint != "use-default":
        print(f"s3_region_endpoint={s3_region_endpoint}")
        spark.sparkContext._jsc.hadoopConfiguration().set(
            "fs.s3a.endpoint", s3_region_endpoint
        )

    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.lakefs.impl", "io.lakefs.LakeFSFileSystem"
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.lakefs.access.key", secret["lakefs-access-key"]
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.lakefs.secret.key", secret["lakefs-secret-key"]
    )
    spark.sparkContext._jsc.hadoopConfiguration().set(
        "fs.lakefs.endpoint", args.lakefs_api_endpoint
    )

    # spark.sparkContext._jsc.hadoopConfiguration().set("fs.s3a.path.style.access", "true")
