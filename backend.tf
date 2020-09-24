terraform {
  backend "s3" {
    bucket         = "760948252845-state-file"
    key            = "terraform_state"
    dynamodb_table = "760948252845-state-lock"
    region         = "eu-west-1"
  }
}
