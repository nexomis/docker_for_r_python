terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  profile = "nexomis-compute"
}

## Input

variable "public_keys" {
  description = "Map of user names and their public SSH keys"
  type = map(string)
}

variable "availability_zone" {
  description = "availability_zone"
  type = string
  default = "eu-west-3c"
}

variable "aws_region" {
  description = "aws region"
  type = string
  default = "eu-west-3"
}

variable "unique_id" {
  description = "unique id"
  type = string
  default = "05071c76"
}


## Create a SSH Key Pair and Register It on AWS

# RSA key of size 4096 bits
resource "tls_private_key" "master" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "master_key-${var.unique_id}"
  public_key = tls_private_key.master.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.master.private_key_openssh
  filename = "master_key.pem"
  file_permission = "0500"
}

## Create a VPC with Public and Private Subnets

resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "Project VPC ${var.unique_id}"
 }
}

resource "aws_subnet" "public" {
 vpc_id            = aws_vpc.main.id
 cidr_block        = "10.0.1.0/24"
 availability_zone = var.availability_zone
 map_public_ip_on_launch = true
 tags = {
   Name = "Public Subnet ${var.unique_id}"
 }
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 tags = {
   Name = "IGW ${var.unique_id}"
 }
}

resource "aws_subnet" "private" {
 vpc_id            = aws_vpc.main.id
 cidr_block        = "10.0.2.0/24"
 availability_zone = var.availability_zone
 tags = {
   Name = "Private Subnet ${var.unique_id}"
 }
}

resource "aws_route_table" "public" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 tags = {
   Name = "Internet routing table ${var.unique_id}"
 }
}

resource "aws_eip" "nat" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  connectivity_type = "public"
  subnet_id     = aws_subnet.public.id
  depends_on = [aws_subnet.public, aws_internet_gateway.gw]
  tags = {
    Name = "nat-gateway-${var.unique_id}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table-${var.unique_id}"
  }
}

resource "aws_route_table_association" "public_subnet_igw" {
 subnet_id      = aws_subnet.public.id
 route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_subnet_nat" {
 subnet_id      = aws_subnet.private.id
 route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "ping" {
  name = "${var.unique_id}-ping"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
  }
}

resource "aws_security_group" "all" {
  name = "${var.unique_id}-all"
  vpc_id = aws_vpc.main.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion" {
  name = "${var.unique_id}-bastion"
  vpc_id = aws_vpc.main.id
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

## Create Bastion Instance

resource "aws_instance" "bastion" {
  ami           = "ami-08fbb6bbadadb326e" # Replace with the actual Debian AMI ID for your region
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.ping.id, aws_security_group.bastion.id]

  tags = {
    Name = "Bastion-${var.unique_id}"
  }
}

## Creating Instances for Each Public Key

resource "aws_instance" "node" {
  for_each     = var.public_keys
  ami          = "ami-08fbb6bbadadb326e"
  instance_type = "t2.small"
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.ping.id]
  tags = {
    Name = "Node-${each.key}-${var.unique_id}"
  }
  user_data = <<-EOF
    #cloud-config
    runcmd:
    - apt-get update
    - apt-get install -y git curl wget ca-certificates
    - curl -fsSL https://get.docker.com -o get-docker.sh
    - sudo sh get-docker.sh
    - sudo usermod -aG docker admin
  EOF
}

## Create the inventory file

resource "local_file" "ansible_inventory" {
  content = <<-EOF
[bastion]
bastion ansible_host=${aws_instance.bastion.public_ip} ansible_user=admin ansible_ssh_private_key_file="./master_key.pem"

[nodes]
%{for instance in aws_instance.node}${instance.tags_all.Name} ansible_host=${instance.private_ip} ansible_user=admin ansible_ssh_private_key_file="./master_key.pem"
%{endfor}

[all:children]
bastion
nodes
  EOF

  filename = "inventory.ini"
}

resource "local_file" "host_vars" {
  for_each = var.public_keys
  content = <<-EOF
pub_key: "${each.value}"
  EOF
  filename = "host_vars/Node-${each.key}-${var.unique_id}.yml"
}

resource "local_file" "group_vars" {
  content = <<-EOF
bastion_public_ip: ${aws_instance.bastion.public_ip}
bastion_private_ip: ${aws_instance.bastion.private_ip}
vpc_net_cidr: "10.0.0.0/16"
public_subnet_cidr: "10.0.1.0/24"
private_subnet_cidr: "10.0.2.0/24"
  EOF
  filename = "group_vars/all.yml"
}

resource "local_file" "ansible_cfg" {
  content = <<-EOF
[defaults]
host_key_checking = False # Optional, disables SSH host key checking
remote_user = your_remote_user

[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i master_key.pem -W %h:%p -q admin@${aws_instance.bastion.public_ip}"
control_path = ~/.ansible/cp/ansible-ssh-%%h-%%p-%%r
scp_if_ssh = True
  EOF
  filename = "ansible.cfg"
}

