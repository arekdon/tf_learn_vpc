resource "aws_vpc" "main" {
  cidr_block = var.cidr_block


  tags = {
      Managedby   = "Terraform"
      Environment = var.environment
      CreatedOn   = timestamp()
      ChangedOn   = timestamp()
      Module      = "tf_learn_vpc"
      Project     = "learning"
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedOn"],
    ]
  }
}