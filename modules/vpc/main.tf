# creating a VPC

resource "aws_vpc" "vpc_res" {
  cidr_block              = var.vpc_cidr
  instance_tenancy        = "default"
  enable_dns_hostnames    = true

  tags      = {
    Name    = "${var.project_name}-vpc"
  }
}


# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id    = aws_vpc.vpc_res.id

  tags      = {
    Name    = "${var.project_name}-igw"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}



# create public subnet az1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.vpc_res.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "public subnet az1"
  }
}

# create public subnet az2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.vpc_res.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "public subnet az2"
  }
}


# create private subnet az1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.vpc_res.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "private subnet az1"
  }
}

# create private subnet az2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.vpc_res.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "private subnet az2"
  }
}

#-----------------------------------------------------------------------------------------------------------

# allocate elastic ip. this eip will be used for the nat-gateway in the public subnet az1 
resource "aws_eip" "eip_for_nat_gateway_az1" {
  domain    = "vpc"

  tags   = {
    Name = "nat gateway az1 eip"
  }
}

# allocate elastic ip. this eip will be used for the nat-gateway in the public subnet az2
resource "aws_eip" "eip_for_nat_gateway_az2" {
  domain   = "vpc"

  tags   = {
    Name = "nat gateway az2 eip"
  }
}

#-------------------------------------------------------------------------------------------------------------------

# create nat gateway in public subnet az1
resource "aws_nat_gateway" "nat_gateway_az1" {
  allocation_id = aws_eip.eip_for_nat_gateway_az1.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags   = {
    Name = "nat gateway az1"
  }

  # to ensure proper ordering, it is recommended to add an explicit dependency
  depends_on = [aws_internet_gateway.internet_gateway]
}

# create nat gateway in public subnet az2
resource "aws_nat_gateway" "nat_gateway_az2" {
  allocation_id = aws_eip.eip_for_nat_gateway_az2.id
  subnet_id     = aws_subnet.public_subnet_az2.id

  tags   = {
    Name = "nat gateway az2"
  }

  # to ensure proper ordering, it is recommended to add an explicit dependency
  # on the internet gateway for the vpc.
  depends_on = [aws_internet_gateway.internet_gateway]
}

#------------------------------------------------------------------Route tables creation-public--------------------------------------------------------------
# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id       = aws_vpc.vpc_res.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags       = {
    Name     = "public route table"
  }
}

#------------------------------------------------------------------Route table association-public -----------------------------------------------------------------------

# associate public subnet az1 to "public route table"
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az1.id
  route_table_id      = aws_route_table.public_route_table.id
}

# associate public subnet az2 to "public route table"
resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az2.id
  route_table_id      = aws_route_table.public_route_table.id
}
#---------------------------------------------------------------------- Route table- private -----------------------------------------------------------------------------------------

# create private route table az1 and add route through nat gateway az1
resource "aws_route_table" "private_route_table_az1" {
  vpc_id            = aws_vpc.vpc_res.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway_az1.id
  }

  tags   = {
    Name = "private route table az1"
  }
}

# create private route table az2 and add route through nat gateway az2
resource "aws_route_table" "private_route_table_az2" {
  vpc_id            = aws_vpc.vpc_res.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway_az2.id
  }

  tags   = {
    Name = "private route table az2"
  }
}

#-------------------------------------------------------------------Route table association - private--------------------------------------------------------------------------------

# associate private subnet az1 with private route table az
resource "aws_route_table_association" "private_subnet_az1_route_table_az1_association" {
  subnet_id         = aws_subnet.private_subnet_az1.id
  route_table_id    = aws_route_table.private_route_table_az1.id
}

# associate private subnet az2 with private route table az
resource "aws_route_table_association" "private_subnet_az2_route_table_az2_association" {
  subnet_id         = aws_subnet.private_subnet_az2.id
  route_table_id    = aws_route_table.private_route_table_az2.id
}

#-------------------------------------------------------------------creating a ec2 instance in pulic and and private  -------------------------------------------------------------------------------------------------

# ... (VPC, Subnet, and Security Group definitions) ...

resource "aws_instance" "public_instance_1" {
  ami                    = var.ami # Replace with your desired AMI ID
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_az1.id 
  vpc_security_group_ids = [var.ec2_security_group_id] # Replace with your security group ID
  key_name               = var.key_name # Replace with your key pair name
  tags = {
    Name = "ec2-public-instance-1"
  }
}

resource "aws_instance" "public_instance_2" {
  ami                    = var.ami # Replace with your desired AMI ID
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_az2.id 
  vpc_security_group_ids = [var.ec2_security_group_id] # Replace with your security group ID
  key_name               = var.key_name # Replace with your key pair name
  tags = {
    Name = "ec2-public-instance-2"
  }
}

resource "aws_instance" "private_instance_1" {
  ami                    = var.ami # Replace with your desired AMI ID
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_az1.id 
  vpc_security_group_ids = [var.ec2_security_group_id] # Replace with your security group ID
  key_name               = var.key_name # Replace with your key pair name
  tags = {
    Name = "ec2-private-instance-1"
  }
}

resource "aws_instance" "private_instance_2" {
  ami                    = var.ami # Replace with your desired AMI ID
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_az2.id 
  vpc_security_group_ids = [var.ec2_security_group_id] # Replace with your security group ID
  key_name               = var.key_name # Replace with your key pair name
  tags = {
    Name = "ec2-private-instance-2"
  }
  
  }