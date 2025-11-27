terraform {
  backend "s3" {
    bucket         = "joon-tfstate-storage-2025"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "joon-tf-lock-table"
    encrypt        = true
  }
}
