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

resource "aws_subnet" "main" {
  
  count = length(var.availability_zone_names)
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = cidrsubnet(var.cidr_block,length(var.availability_zone_names),count.index)
  availability_zone = var.availability_zone_names[count.index]

  tags = {
      Managedby   = "Terraform"
      Environment = var.environment
      CreatedOn   = timestamp()
      ChangedOn   = timestamp()
      Module      = "tf_learn_vpc"
      Project     = "learning"
      ResourceType = "Subnet"
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedOn"],
    ]
  }
}