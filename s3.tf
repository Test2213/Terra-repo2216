resource "aws_s3_bucket" "test-s3-bucketels" {
  bucket = "my-tf-test-s3bucket-431"

  tags = {
    Name        = "My bucket"
    Environment = "lab"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.test-s3-bucketels.id
  eventbridge = true
}

