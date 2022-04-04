# Purpose:
# Generate sample data.
# Test creating a new LakeFS branch
# Test write data to LakeFS using S3A endpoint.
# Test create Glue catalog entry over LakeFS using S3A endpoint.
# Test committing changes to the branch

import sys

sys.path.insert(0, "utils.zip")
import utils

from datetime import datetime

from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

import lakefs_client
from lakefs_client.api import branches_api, commits_api
from lakefs_client.model.branch_creation import BranchCreation
from lakefs_client.model.commit_creation import CommitCreation


#####################################################
#####################################################
#####################################################

args = utils.get_args()

bucket = args.lakefs_s3_bucket
repo_name = args.lakefs_repo_name

secret = utils.get_secret(args)
configuration = lakefs_client.Configuration(
    host=args.lakefs_api_endpoint,
    username=secret["lakefs-access-key"],
    password=secret["lakefs-secret-key"],
)


#####################################################
#####################################################
#####################################################

# Generate new branch name
now_datetime = datetime.now()

now_yyyy_mm_dd = now_datetime.strftime("%Y-%m-%d")
now_hh_mm = now_datetime.strftime("%H-%M")
branch_name = f"branch_{now_yyyy_mm_dd}_{now_hh_mm}"

with lakefs_client.ApiClient(configuration) as api_client:
    # Create an instance of the API class
    api_instance = branches_api.BranchesApi(api_client)
    repository = repo_name
    branch_creation = BranchCreation(
        name=branch_name,
        source="main",
    )  # BranchCreation |

    # example passing only required values which don't have defaults set
    try:
        # create branch
        api_response = api_instance.create_branch(repository, branch_creation)
        print(api_response)
    except lakefs_client.ApiException as e:
        print("Exception when calling BranchesApi->create_branch: %s\n" % e)
        raise

##############################################################
##############################################################
##############################################################

df = utils.create_sample_df()

# Write data to LakeFS table via LakeFS filesystem on S3
utils.configure_lakefs(args)

# Write data using dataframe API
output = f"lakefs://{repo_name}/{branch_name}/data/sample_data_lakefs/"
print(output)
df.write.partitionBy(["yyyy_mm_dd", "hh_mm"]).parquet(output)
df.createOrReplaceTempView("df")

##############################################################
##############################################################
##############################################################

with lakefs_client.ApiClient(configuration) as api_client:
    # Create an instance of the API class
    api_instance = commits_api.CommitsApi(api_client)
    repository = repo_name
    branch = branch_name
    commit_creation = CommitCreation(
        message="example commit message"
    )  # CommitCreation |

    # example passing only required values which don't have defaults set
    try:
        # create commit
        api_response = api_instance.commit(repository, branch, commit_creation)
        print(api_response)
    except lakefs_client.ApiException as e:
        print("Exception when calling CommitsApi->commit: %s\n" % e)
        raise


##############################################################
##############################################################
##############################################################
