terraform {
  backend "s3" {
    bucket         = "cybergkstate"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = null
    encrypt        = true
  }
}
