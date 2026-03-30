
provider "aws" {
  region = "us-east-2"
}



# s3 bucket create #
resource "aws_s3_bucket" "tf_state" {
  bucket = "sagar-tf-state-123457891"

}


# enable versionoing #
resource "aws_s3_bucket_versioning" "versionoing" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}



# dynamodb #
resource "aws_dynamodb_table" "lock" {
    name = "terrafrom_lock"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
      name = "LockID"
      type = "S"
    }
}