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

// Create subnets based on AZs provided as input
resource "aws_subnet" "main" {
  
  count = length(var.availability_zone_names)
  vpc_id     = aws_vpc.main.id
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

// Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

// Create Elastic IP for NAT gw
resource "aws_eip" "ngweip" {
  vpc      = true

  depends_on = [aws_internet_gateway.igw]
}

// Create Nat Gateway in first subnet
// TODO: make this choice somehow intelligent, split into haf of private and half of public subnets
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngweip.id
  subnet_id     = aws_subnet.main[0].id

  depends_on = [aws_internet_gateway.igw,aws_eip.ngweip]
}