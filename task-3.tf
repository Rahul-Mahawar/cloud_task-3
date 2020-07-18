provider "aws" {
  region     = "ap-south-1"
  profile    = "rk.18"
}

resource "tls_private_key" "taskkey" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "key" {
 key_name = "my-key"
 public_key = "${tls_private_key.taskkey.public_key_openssh}"
 depends_on = [
    tls_private_key.taskkey
    ]
}

resource "local_file" "key1" {
 content = "${tls_private_key.taskkey.private_key_pem}"
 filename = "my-key.pem"
  depends_on = [
    aws_key_pair.key
   ]
}

resource "aws_vpc" "test-env" {
   cidr_block = "192.168.0.0/16"
   enable_dns_hostnames = true
   enable_dns_support = true
   tags ={
     Name = "test-env"
   }
 }

 
resource "aws_subnet" "public_subnet" {
   vpc_id = "${aws_vpc.test-env.id}"
   map_public_ip_on_launch = "true"
   cidr_block = "192.168.0.0/24"
   availability_zone = "ap-south-1a"
 }
resource "null_resource" "nulllocal1"  {

depends_on = [
    aws_vpc.test-env,
  ]
 }
 
resource "aws_subnet" "private_subnet" {
   vpc_id = "${aws_vpc.test-env.id}"
   map_public_ip_on_launch = "true"
   cidr_block = "192.168.1.0/24"
   availability_zone = "ap-south-1a"
 }
resource "null_resource" "nulllocal12"  {

depends_on = [
    aws_vpc.test-env,
  ]
 }


resource "aws_internet_gateway" "InterNetGateWay" {
  vpc_id = "${aws_vpc.test-env.id}"
  tags ={
    Name= "InternetGateWay"
  }

}
resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.test-env.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.InterNetGateWay.id}"
  }
tags ={
    Name= "RoutTable"
  }

}
resource "aws_route_table_association" "subnet_public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}


resource "aws_security_group" "wp" {
  vpc_id = "${aws_vpc.test-env.id}"
  name        = "task2sg"
  
  ingress {
    description = "TCP"
    from_port   = 80	
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
     description = "SSH"
     from_port   = 22	
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]

}
  egress {
     from_port   = 0	
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]

}  
  tags = {
    Name = "task2sg"
  }
}

resource "null_resource" "nulllocal2"  {


depends_on = [
    aws_vpc.test-env,
  ]
}


resource "aws_security_group" "mysql" {
  name = "MYSQL"
  description = "managed by terrafrom for mysql servers"
  vpc_id = "${aws_vpc.test-env.id}"
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.wp.id}"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name= "MYSQL"
  }

}
resource "aws_instance" "wp_Instance" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.wp.id}"]
  key_name = "my-key"
 tags ={
    Name= "instance_wp"
  }
}

resource "null_resource" "nulllocal31"  {


depends_on = [
    aws_vpc.test-env,
    aws_key_pair.key
  ]
}

resource "aws_instance" "mysql_Instance" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.mysql.id}"]
  key_name = "my-key"
 tags ={
    Name= "instance_mysql"
  }
}

resource "null_resource" "nulllocal41"  {


depends_on = [
    aws_vpc.test-env,
    aws_key_pair.key
  ]
}


resource "null_resource" "nulllocal100"  {


depends_on = [
     aws_instance.wp_Instance
  ]

	provisioner "local-exec" {
	    command = "chrome  ${aws_instance.wp_Instance.public_ip}"
  	}

}
