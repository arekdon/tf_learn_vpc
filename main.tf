resource "aws_vpc" "main" {
  cidr_block = var.cidr_block


  tags = {
      Managedby = "Terraform"
      Environment = var.environment
      CreatedOn   = timestamp()
  }
}