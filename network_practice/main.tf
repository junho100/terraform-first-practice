resource "aws_vpc" "template_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "dev-${var.project_name}-vpc"
  }
}

resource "aws_subnet" "template_public_subnet" {
    count = 4
    vpc_id = aws_vpc.template_vpc.id
    cidr_block = "10.1.${count.index}.0/24"
    availability_zone = count.index % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
    tags = {
      Name = "dev-${var.project_name}-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "template_private_subnet" {
  vpc_id = aws_vpc.template_vpc.id
  cidr_block = "10.1.6.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-${var.project_name}-private-subnet"
  }
}

resource "aws_internet_gateway" "template_internet_gateway" {
  tags = {
    Name = "dev-${var.project_name}-igw"
  }
}

resource "aws_internet_gateway_attachment" "template_internet_gateway_attachment" {
    internet_gateway_id = aws_internet_gateway.template_internet_gateway.id
    vpc_id = aws_vpc.template_vpc.id
}

resource "aws_eip" "template_nat_gateway_eip" {
    tags = {
        Name = "dev-${var.project_name}-nat-eip"
    }
}

resource "aws_nat_gateway" "template_nat_gateway" {
    allocation_id = aws_eip.template_nat_gateway_eip.allocation_id
    subnet_id = aws_subnet.template_public_subnet[0].id
    tags = {
        Name = "dev-${var.project_name}-nat"
    }
}

resource "aws_route_table" "template_public_route_table" {
    vpc_id = aws_vpc.template_vpc.id
    tags = {
        Name = "dev-${var.project_name}-public-rt"
    }
}

resource "aws_route_table" "template_private_route_table" {
    vpc_id = aws_vpc.template_vpc.id
    tags = {
        Name = "dev-${var.project_name}-private-rt"
    }
}

resource "aws_route" "template_public_route" {
    route_table_id = aws_route_table.template_public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.template_internet_gateway.id
}

resource "aws_route" "template_private_route" {
    route_table_id = aws_route_table.template_private_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.template_nat_gateway.id
}

resource "aws_route_table_association" "template_public_subnet_rt_association" {
    count = length(aws_subnet.template_public_subnet)
    subnet_id = aws_subnet.template_public_subnet[count.index].id
    route_table_id = aws_route_table.template_public_route_table.id
}

resource "aws_route_table_association" "template_private_subnet_rt_association" {
    subnet_id = aws_subnet.template_private_subnet.id
    route_table_id = aws_route_table.template_private_route_table.id
}