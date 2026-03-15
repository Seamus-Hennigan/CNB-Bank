resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
      name = "${var.project_name}-vpc"
      Enviroment = var.enviornment
    }
  
}


resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        name = "${var.project_name}-igw"
        Enviroment = var.enviornment
    }
}


resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    
    map_public_ip_on_launch = true
    
    tags = {
        name = "${var.project_name}-public-subnet-${count.index + 1}"
        Environment = var.enviornment
    }
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    tags = {
        name = "${var.project_name}-private-subnet-${count.index + 1}"
        Environment = var.enviornment
    }
}

resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
      Name = "${var.project_name}-nat-eip"
      Environment = var.enviornment
    }
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id

    tags = {
        Name = "${var.project_name}-nat-gateway"
        Environment = var.enviornment
    }

}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        name = "${var.project_name}-public-rt"
        Environment = var.enviornment
    }
  
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        name = "${var.project_name}-private-rt"
        Environment = var.enviornment
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