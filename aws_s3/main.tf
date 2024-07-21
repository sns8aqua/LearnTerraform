# This block defines the required providers for Terraform.
# Providers are plugins that enable interaction with cloud providers, SaaS providers, and other APIs.
# In this case, we are specifying the AWS provider with a version constraint.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Specifies the source of the provider. Here, 'hashicorp/aws' refers to the AWS provider maintained by HashiCorp.
      version = "~> 4.16"        # Specifies the version constraint for the AWS provider. The '~>' operator means any version >= 4.16 and < 5.0.
    }
  }
}

# This block configures the AWS provider. 
# The provider is responsible for managing the lifecycle of AWS resources.
# The `region` attribute specifies the AWS region to create resources in.

provider "aws" {
  region = "us-west-2"  # Specifies the AWS region. In this case, it's the US West (Oregon) region.
}

# This resource block defines an S3 bucket resource.
# The `aws_s3_bucket` resource is used to create an S3 bucket in AWS.
# The `testingbucket` is the logical name for this resource within the Terraform configuration.

resource "aws_s3_bucket" "testingbucket" {
  bucket = "bucket-list-bugger"  # Specifies the name of the S3 bucket. Bucket names must be globally unique across all existing bucket names in Amazon S3.
  tags = {
    Name        = "test bucket"        # Tags are key-value pairs used for organizing resources. This tag sets the Name of the bucket.
    Description = "Testing the bucket"  # This tag provides a description for the bucket.
  }
}

# This resource block defines an S3 object resource.
# The `aws_s3_object` resource is used to manage objects within an S3 bucket.
# The `bucket_test` is the logical name for this resource within the Terraform configuration.

resource "aws_s3_object" "bucket_test" {
  bucket = aws_s3_bucket.testingbucket.id  # Refers to the ID of the S3 bucket created in the previous resource block.
  key    = "test.doc"                      # Specifies the key (or name) for the S3 object. This is the name of the file in the bucket.
  source = "/Users/sathya/Documents/terraform_basic/aws_s3/test.doc"  # Specifies the path to the source file on the local filesystem. This file will be uploaded to the S3 bucket.
}

# This data block fetches information about an existing IAM group.
# The `aws_iam_group` data source is used to read information about an IAM group in AWS.
# The `test_data` is the logical name for this data source within the Terraform configuration.

data "aws_iam_group" "test_data" {
  group_name = "test"  # Specifies the name of the IAM group to read. This must match the name of an existing IAM group in your AWS account.
}

# This resource block defines a bucket policy for the S3 bucket.
# The `aws_s3_bucket_policy` resource is used to set the access policy for an S3 bucket.
# The `test_policy` is the logical name for this resource within the Terraform configuration.

resource "aws_s3_bucket_policy" "test_policy" {
  bucket = aws_s3_bucket.testingbucket.id  # Refers to the ID of the S3 bucket created in the `aws_s3_bucket` resource block.
  policy = <<EOF
    {
      "Version": "2012-10-17",  # Specifies the version of the policy language.
      "Id": "MYBUCKETPOLICY",   # An optional identifier for the policy.
      "Statement": [            # An array of statements (rules) for the policy.
        {
          "Sid": "IPAllow",    # Optional identifier for the statement.
          "Effect": "Deny",    # The effect of the statement. In this case, it denies access.
          "Principal": "*",    # Specifies the principal (account, user, role) to which the policy applies. '*' means the policy applies to everyone.
          "Action": "s3:*",    # Specifies the actions that are allowed or denied. 's3:*' means all S3 actions.
          "Resource": [
            "arn:aws:s3:::${aws_s3_bucket.testingbucket.id}",    # Specifies the ARN (Amazon Resource Name) of the S3 bucket.
            "arn:aws:s3:::${aws_s3_bucket.testingbucket.id}/*"  # Specifies the ARN of all objects within the S3 bucket.
          ],
          "Condition": {        # Specifies the condition that must be met for the policy to apply.
            "IpAddress": {
              "aws:SourceIp": "8.8.8.8/32"  # The condition specifies that access is denied for requests from the IP address 8.8.8.8.
            }
          }
        }
      ]
    }
    EOF
}
