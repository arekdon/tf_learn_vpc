resource "aws_vpc" "main" {
  cidr_block = var.cidr_block


  tags = {
      Managedby   = "Terraform"
      Environment = var.environment
      CreatedOn   = timestamp()
      ChangedOn   = timestamp()
      Module      = "tf_learn_vpc"
      Project     = "learning"
      Name        = "VPC-${var.environment}"
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
      Name         = "Public-Subnet-${count.index}"
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
      Name         = "Private-Subnet-${count.index}"
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
  destination_cidr_block    = "0.0.0.0/0"
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

//Standard NACL for Private Subnet
resource "aws_network_acl" "private_subnets_nacl" {
  vpc_id = aws_vpc.main.id

// Standard ranges as recommended by AWS
// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-recommended-nacl-rules.html
// Management ports 22 and 3389
// Ephemeral Range 32768 - 65535


  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 32768
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 3389
    to_port    = 3389
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 3389
    to_port    = 3389
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 32768
    to_port    = 65535
  }


  tags = {
    Managedby     = "Terraform"
    Environment   = var.environment
    CreatedOn     = timestamp()
    ChangedOn     = timestamp()
    Module        = "tf_learn_vpc"
    Project       = "learning"
    ResourceType  = "NACL"
    Name          = "PrivateNACL"
  }
}

//Standard NACL for Public Subnet
resource "aws_network_acl" "public_subnets_nacl" {
  vpc_id = aws_vpc.main.id

// Standard ranges as recommended by AWS
// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-recommended-nacl-rules.html
// Management ports 22 and 3389
// Ephemeral Range 32768 - 65535


  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Managedby     = "Terraform"
    Environment   = var.environment
    CreatedOn     = timestamp()
    ChangedOn     = timestamp()
    Module        = "tf_learn_vpc"
    Project       = "learning"
    ResourceType  = "NACL"
    Name          = "PublicNACL"
  }
}


// Enable Flowlogs

resource "aws_flow_log" "flowlog" {
  iam_role_arn    = aws_iam_role.flowlog.arn
  log_destination = aws_cloudwatch_log_group.flowlog.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "flowlog" {
  name = "flowlog"
}

resource "aws_iam_role" "flowlog" {
  name = "flowlog"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flowlog" {
  name = "flowlog"
  role = aws_iam_role.flowlog.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

// Get list of subnet ids, for private subnet only
data "aws_subnet_ids" "private" {
  vpc_id   = aws_vpc.main.id
  tags = {
    Name   = "Private*"
  }

depends_on = [aws_subnet.private_subnets]

}

//Create db subnet group
resource "aws_db_subnet_group" "dbmain" {
  
  subnet_ids = data.aws_subnet_ids.private.ids

depends_on = [aws_subnet.private_subnets]

}