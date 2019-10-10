provider "aws" {
  region = "ap-south-1"
}

## VPC Creation
resource "aws_vpc" "km-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "km-vpc"
  }
}

## Private Subnet Creation
resource "aws_subnet" "km_private_subnet1" {
       #arn                             = (known after apply)
       assign_ipv6_address_on_creation = false
       availability_zone               = "ap-south-1b"
       #availability_zone_id            = (known after apply)
       cidr_block                      = "10.0.1.0/24"
       #id                              = (known after apply)
       #ipv6_cidr_block                 = (known after apply)
       #ipv6_cidr_block_association_id  = (known after apply)
       #map_public_ip_on_launch         = false
       #owner_id                        = (known after apply)
       tags                             = {
	"Name" = "kmprivatesubnet1"
       }
       vpc_id                          = "${aws_vpc.km-vpc.id}"
}

## Public Subnet Creation
resource "aws_subnet" "km_public_subnet1" {
       #arn                             = (known after apply)
       assign_ipv6_address_on_creation = false
       availability_zone               = "ap-south-1a"
       #availability_zone_id            = (known after apply)
       cidr_block                      = "10.0.2.0/24"
       #id                              = (known after apply)
       #ipv6_cidr_block                 = (known after apply)
       #ipv6_cidr_block_association_id  = (known after apply)
       map_public_ip_on_launch         = true
       #owner_id                        = (known after apply)
       tags                            = {
	 "Name" = "km_public_subnet1"
       }
       vpc_id                          = "${aws_vpc.km-vpc.id}"
}

## Internet Gateway
resource "aws_internet_gateway" "km-igw" {
   #id       = (known after apply)
   #owner_id = (known after apply)
   tags     = {
       "Name" = "km-main-igw"
    }
   vpc_id   = "${aws_vpc.km-vpc.id}"
}

## Security Group
resource "aws_security_group" "km-security-group" {
  name        = "km-security-group"
  description = "Allow All tcp inbound traffic"
  vpc_id = "${aws_vpc.km-vpc.id}"
  ingress {
    # TLS (change to whatever ports you need)
    #from_port   = 0
    from_port   = 0
    #to_port     = 0
    to_port     = 0
    protocol    = "-1" # Value -1 mentions all protocol. use value of from_port and to_port to be 0 with this.
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "km-sg"
  }
}

## Route Table for Public Subnet
resource "aws_route_table" "routetable_public_subnet" {
    vpc_id = "${aws_vpc.km-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.km-igw.id}"
    }

    tags = {
        Name = "PublicSubnetRouteTable"
    }
}

## Public Subnet Association with custom route table
resource "aws_route_table_association" "routetableassc_public_subnet" {
    subnet_id = "${aws_subnet.km_public_subnet1.id}"
    route_table_id = "${aws_route_table.routetable_public_subnet.id}"
}


## EC2 Instance Creation
resource "aws_instance" "webserver1" {
  ami           = "ami-073251dd98f09df06"
  instance_type = "t2.micro"
  iam_instance_profile = "EC2-SSM-Role"
  vpc_security_group_ids = ["${aws_security_group.km-security-group.id}"]
  associate_public_ip_address  = true
  key_name      = "default"
  tags          = {
    Name = "webserver1"
  }
  user_data = "${file("pre-install.sh")}"
  subnet_id = "${aws_subnet.km_public_subnet1.id}"
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./default.pem -i '${aws_instance.webserver1.public_ip},' deploy.yml"
}
}
