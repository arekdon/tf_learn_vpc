resource "aws_vpc" "main" {
  cidr_block = var.cidr_block


  tags = {
      Managedby   = "Terraform"
      Environment = var.environment
      CreatedOn   = timestamp()
      Module      = "tf_learn_vpc"
      Project     = "learning"
  }
}