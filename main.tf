provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "capstone-media-bucket" {
  bucket        = "capstone-media-bucket"
  force_destroy = true
  tags = {
    Name = "capstone-media-bucket"
  }
}
resource "aws_s3_bucket_policy" "capstone-media-bucket-policy" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.capstone-media-bucket.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_s3_bucket_public_access_block" "media_bucket_access_block" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket" "capstone-code-bucket" {
  bucket        = "capstone-code-bucket"
  force_destroy = true
  tags = {
    Name = "capstone-code-bucket"
  }
}

