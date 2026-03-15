resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostNames = true
    enable_dns_support = true

    tags = {
      Name = "${var.project_Name}-vpc"
      Environment = var.Environment
    }
  
}


resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project_Name}-igw"
        Environment = var.Environment
    }
}


resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    
    map_public_ip_on_launch = true
    
    tags = {
        Name = "${var.project_Name}-public-subnet-${count.index + 1}"
        Environment = var.Environment
    }
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    tags = {
        Name = "${var.project_Name}-private-subnet-${count.index + 1}"
        Environment = var.Environment
    }
}

resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
      Name = "${var.project_Name}-nat-eip"
      Environment = var.Environment
    }
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id

    tags = {
        Name = "${var.project_Name}-nat-gateway"
        Environment = var.Environment
    }

}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${var.project_Name}-public-rt"
        Environment = var.Environment
    }
  
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "${var.project_Name}-private-rt"
        Environment = var.Environment
    }
  
}

resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count = length(aws_subnet.private)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}