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

// Create public subnets
// TODO: Protection AZs = public_subnets length
resource "aws_subnet" "public_subnets" {
  
  count = length(var.public_subnets_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets_cidr_block[count.index]
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

// Create private subnets
// TODO: Protection AZs = private_subnets length
resource "aws_subnet" "private_subnets" {
  
  count = length(var.private_subnets_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr_block[count.index]
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
  subnet_id     = aws_subnet.public_subnets[0].id

  depends_on = [aws_internet_gateway.igw,aws_eip.ngweip]
}


// Create public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
      Managedby     = "Terraform"
      Environment   = var.environment
      CreatedOn     = timestamp()
      ChangedOn     = timestamp()
      Module        = "tf_learn_vpc"
      Project       = "learning"
      ResourceType  = "RouteTable"
      Name          = "PublicRT"
  }
}

// Create private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
      Managedby     = "Terraform"
      Environment   = var.environment
      CreatedOn     = timestamp()
      ChangedOn     = timestamp()
      Module        = "tf_learn_vpc"
      Project       = "learning"
      ResourceType  = "RouteTable"
      Name          = "PrivateRT"
  }
}

// Public RT routes
resource "aws_route" "public_routes" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
  depends_on                = [aws_route_table.public_rt,aws_internet_gateway.igw]
}

// Private RT routes
resource "aws_route" "private_routes" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = join("",[aws_eip.ngweip.private_ip,"/32"])
  nat_gateway_id            = aws_nat_gateway.ngw.id
  depends_on                = [aws_route_table.private_rt,aws_eip.ngweip]
}

// Create association of RT to public subnets
resource "aws_route_table_association" "public_association" {
  count          = length(var.public_subnets_cidr_block)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

// Create association of RT to private subnets
resource "aws_route_table_association" "private_association" {
  count          = length(var.private_subnets_cidr_block)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}