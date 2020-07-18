# cloud_task-3
# Infrastructure as code using terraform, which automatically create a VPC on AWS

## Amazon Virtual Private Cloud (VPC):-
Amazon Virtual Private Cloud (Amazon VPC) lets you provision a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you define. You have complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways. You can use both IPv4 and IPv6 in your VPC for secure and easy access to resources and applications.

## Problem Statement:
- We have to create a web portal for our company with all the security as much as possible.

- So, we use Wordpress software with dedicated database server.

- Database should not be accessible from the outside world for security purposes.

- We only need to public the WordPress to clients.

- So, here are the steps for proper understanding!

# Steps:

1) Write a Infrastructure as code using terraform, which automatically create a VPC.

2) In that VPC we have to create 2 subnets:

  a) public subnet [ Accessible for Public World! ] 

  b) private subnet [ Restricted for Public World! ]

3) Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.

4) Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.

5) Launch an ec2 instance which has Wordpress setup already having the security group allowing port 80 so that our client can connect to our wordpress site.

Also attach the key to instance for further login into it.

6) Launch an ec2 instance which has MYSQL setup already with security group allowing port 3306 in private subnet so that our wordpress vm can connect with the same.

Also attach the key with the same.

# Implementation:

Firstly, we Create the profile , specify region and for plugins.
``` html
provider "aws" {
  region     = "ap-south-1"
  profile    = "rk.18"
}
```

## Step 1: Now, we have to create VPC. For this we require CIDR block to specify range of IPv4 addresses for the VPC and a name tag for unique identification.
``` html
* Create VPC

resource "aws_vpc" "test-env" {
   cidr_block = "192.168.0.0/16"
   enable_dns_hostnames = true
   enable_dns_support = true
   tags ={
     Name = "test-env"
   }
}
```
![alt text](/task3-images/vpc.jpg)


## Step 2: In that VPC we have to create 2 subnets:

a) public subnet [ Accessible for Public World! ] 

``` html
* public subnet

resource "aws_subnet" "public_subnet" {
   vpc_id = "${aws_vpc.test-env.id}"
   map_public_ip_on_launch = "true"
   cidr_block = "192.168.0.0/24"
   availability_zone = "ap-south-1a"
 }
```

b) private subnet [ Restricted for Public World! ]

``` html
* private subnet

resource "aws_subnet" "private_subnet" {
   vpc_id = "${aws_vpc.test-env.id}"
   map_public_ip_on_launch = "true"
   cidr_block = "192.168.1.0/24"
   availability_zone = "ap-south-1a"
 }
```

![alt text](/task3-images/subnet.jpg)


## Step 3 : Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.

``` html
* gateway

resource "aws_internet_gateway" "InterNetGateWay" {
  vpc_id = "${aws_vpc.test-env.id}"
  tags ={
    Name= "InternetGateWay"
  }
}
```
![alt text](/task3-images/igw.jpg)

## Step 4: Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.

``` html
* routing table

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.test-env.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.InterNetGateWay.id}"
    
}


resource "aws_route_table_association" "subnet_public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}
```
![alt text](/task3-images/rtable.jpg)


## Step 5: Launch an ec2 instance which has Wordpress setup already having the security group allowing port 80 so that our client can connect to our wordpress site.

``` html
* security group(Wordpress)

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
```
- This security group only allow ping, ssh and httpd.

![alt text](/task3-images/sg.jpg)

Now we can create our instance. For creating any instance we need AMI,instance type,availability zone which we have mentioned earlier in subnet and key - here I used pre-existing key. For WordPress AMI, I used WordPress Base Version which requires subscription for that.

``` html
* WordPress Instance

resource "aws_instance" "wp_Instance" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.wp.id}"]
  key_name = "taskkey"
 tags ={
    Name= "instance_wp"
  }
}
```

![alt text](/task3-images/ins.jpg)


## Step 6: Launch an ec2 instance which has MYSQL setup already with security group allowing port 3306 in private subnet so that our wordpress vm can connect with the same.

``` html
* security group(MYSQL)

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
}
```
![alt text](/task3-images/sg.jpg)


## Creating Instance.

 ``` html
* MYSQL Instance

resource "aws_instance" "mysql_Instance" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.mysql.id}"]
  key_name = "taskkey"
 tags ={
    Name= "instance_mysql"
  }
}
```
![alt text](/task3-images/ins.jpg)


# Then, Run the Terraform Code.

``` html
terraform init
```

# - Apply Terraform.

``` html
terraform apply -auto-approve
```

# - And at the end delete or destroy the complete process.

``` html
terraform destroy -auto-approve
```

## Thank You!!!

[Rahul Mahawar :))](https://www.linkedin.com/in/rahul-mahawar-448333194/)
