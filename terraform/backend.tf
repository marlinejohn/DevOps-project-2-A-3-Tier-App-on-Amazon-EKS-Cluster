terraform {
  backend "s3" {
    bucket         = "marline-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "marline-terraform-lock"
    encrypt        = true
  }
}
