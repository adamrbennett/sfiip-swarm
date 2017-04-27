variable "region" {}

resource "aws_vpc" "sfiip" {
  cidr_block = "172.30.0.0/16"
  tags {
    Name = "sfiip"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.sfiip.id}"

  ingress {
    protocol  = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "pub1a" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.0.0/24"
  availability_zone = "${var.region}a"
  tags {
    Name = "sfiip-pub-1a"
  }
}

resource "aws_subnet" "pub1b" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.1.0/24"
  availability_zone = "${var.region}b"
  tags {
    Name = "sfiip-pub-1b"
  }
}

resource "aws_subnet" "pub1c" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.2.0/24"
  availability_zone = "${var.region}c"
  tags {
    Name = "sfiip-pub-1c"
  }
}

resource "aws_subnet" "infra1a" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.10.0/24"
  availability_zone = "${var.region}a"
  tags {
    Name = "sfiip-infra-1a"
  }
}

resource "aws_subnet" "infra1b" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.11.0/24"
  availability_zone = "${var.region}b"
  tags {
    Name = "sfiip-infra-1b"
  }
}

resource "aws_subnet" "infra1c" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.12.0/24"
  availability_zone = "${var.region}c"
  tags {
    Name = "sfiip-infra-1c"
  }
}

resource "aws_subnet" "mgr1a" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.20.0/24"
  availability_zone = "${var.region}a"
  tags {
    Name = "sfiip-mgr-1a"
  }
}

resource "aws_subnet" "mgr1b" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.21.0/24"
  availability_zone = "${var.region}b"
  tags {
    Name = "sfiip-mgr-1b"
  }
}

resource "aws_subnet" "mgr1c" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.22.0/24"
  availability_zone = "${var.region}c"
  tags {
    Name = "sfiip-mgr-1c"
  }
}

resource "aws_subnet" "wrk1a" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.30.0/24"
  availability_zone = "${var.region}a"
  tags {
    Name = "sfiip-wrk-1a"
  }
}

resource "aws_subnet" "wrk1b" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.31.0/24"
  availability_zone = "${var.region}b"
  tags {
    Name = "sfiip-wrk-1b"
  }
}

resource "aws_subnet" "wrk1c" {
  vpc_id = "${aws_vpc.sfiip.id}"
  cidr_block = "172.30.32.0/24"
  availability_zone = "${var.region}c"
  tags {
    Name = "sfiip-wrk-1c"
  }
}

resource "aws_internet_gateway" "sfiip" {
  vpc_id = "${aws_vpc.sfiip.id}"

  tags {
    Name = "sfiip-igw"
  }
}

resource "aws_route_table" "pub" {
  vpc_id = "${aws_vpc.sfiip.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sfiip.id}"
  }
  tags {
    Name = "public"
  }
}

resource "aws_route_table_association" "pub1a" {
  subnet_id      = "${aws_subnet.pub1a.id}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_route_table_association" "pub1b" {
  subnet_id      = "${aws_subnet.pub1b.id}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_route_table_association" "pub1c" {
  subnet_id      = "${aws_subnet.pub1c.id}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_route_table" "pvt" {
  vpc_id = "${aws_vpc.sfiip.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.natgw1a.id}"
  }
  tags {
    Name = "private"
  }
}

resource "aws_route_table_association" "infra1a" {
  subnet_id      = "${aws_subnet.infra1a.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "infra1b" {
  subnet_id      = "${aws_subnet.infra1b.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "infra1c" {
  subnet_id      = "${aws_subnet.infra1c.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "mgr1a" {
  subnet_id      = "${aws_subnet.mgr1a.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "mgr1b" {
  subnet_id      = "${aws_subnet.mgr1b.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "mgr1c" {
  subnet_id      = "${aws_subnet.mgr1c.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "wrk1a" {
  subnet_id      = "${aws_subnet.wrk1a.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "wrk1b" {
  subnet_id      = "${aws_subnet.wrk1b.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_route_table_association" "wrk1c" {
  subnet_id      = "${aws_subnet.wrk1c.id}"
  route_table_id = "${aws_route_table.pvt.id}"
}

resource "aws_eip" "nat1a" {
  vpc = true
}

resource "aws_nat_gateway" "natgw1a" {
  allocation_id = "${aws_eip.nat1a.id}"
  subnet_id     = "${aws_subnet.pub1a.id}"
}

resource "aws_network_acl" "public" {
  vpc_id = "${aws_vpc.sfiip.id}"

  subnet_ids = [
    "${aws_subnet.pub1a.id}",
    "${aws_subnet.pub1b.id}",
    "${aws_subnet.pub1c.id}"
  ]

  ingress {
    protocol   = "all"
    rule_no    = 1
    action     = "allow"
    cidr_block = "172.30.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 1000
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "udp"
    rule_no    = 1001
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "all"
    rule_no    = 1
    action     = "allow"
    cidr_block = "172.30.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 1000
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "udp"
    rule_no    = 1001
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "public"
  }
}

resource "aws_network_acl" "private" {
  vpc_id = "${aws_vpc.sfiip.id}"

  subnet_ids = [
    "${aws_subnet.infra1a.id}",
    "${aws_subnet.infra1b.id}",
    "${aws_subnet.infra1c.id}",
    "${aws_subnet.mgr1a.id}",
    "${aws_subnet.mgr1b.id}",
    "${aws_subnet.mgr1c.id}",
    "${aws_subnet.wrk1a.id}",
    "${aws_subnet.wrk1b.id}",
    "${aws_subnet.wrk1c.id}"
  ]

  ingress {
    rule_no        = 1
    protocol       = "all"
    action         = "allow"
    cidr_block     = "172.30.0.0/16"
    from_port      = 0
    to_port        = 0
  }

  ingress {
    rule_no        = 1000
    protocol       = "tcp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 1024
    to_port        = 65535
  }

  ingress {
    rule_no        = 1001
    protocol       = "udp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 1024
    to_port        = 65535
  }

  egress {
    rule_no        = 1
    protocol       = "all"
    action         = "allow"
    cidr_block     = "172.30.0.0/16"
    from_port      = 0
    to_port        = 0
  }

  egress {
    rule_no        = 100
    protocol       = "tcp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 22
    to_port        = 22
  }

  egress {
    rule_no        = 110
    protocol       = "udp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 53
    to_port        = 53
  }

  egress {
    rule_no        = 120
    protocol       = "tcp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 80
    to_port        = 80
  }

  egress {
    rule_no        = 130
    protocol       = "tcp"
    action         = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = 443
    to_port        = 443
  }

  tags {
    Name = "private"
  }
}

// output

output "vpc_id" {
  value = "${aws_vpc.sfiip.id}"
}

output "pub1a_subnet_id" {
  value = "${aws_subnet.pub1a.id}"
}

output "pub1b_subnet_id" {
  value = "${aws_subnet.pub1b.id}"
}

output "pub1c_subnet_id" {
  value = "${aws_subnet.pub1c.id}"
}

output "infra1a_subnet_id" {
  value = "${aws_subnet.infra1a.id}"
}

output "infra1b_subnet_id" {
  value = "${aws_subnet.infra1b.id}"
}

output "infra1c_subnet_id" {
  value = "${aws_subnet.infra1c.id}"
}

output "mgr1a_subnet_id" {
  value = "${aws_subnet.mgr1a.id}"
}

output "mgr1b_subnet_id" {
  value = "${aws_subnet.mgr1b.id}"
}

output "mgr1c_subnet_id" {
  value = "${aws_subnet.mgr1c.id}"
}

output "wrk1a_subnet_id" {
  value = "${aws_subnet.wrk1a.id}"
}

output "wrk1b_subnet_id" {
  value = "${aws_subnet.wrk1b.id}"
}

output "wrk1c_subnet_id" {
  value = "${aws_subnet.wrk1c.id}"
}

output "vpc_default_security_group_id" {
  value = "${aws_default_security_group.default.id}"
}
