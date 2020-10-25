# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# creating vpc
resource "aws_vpc" "terraform" {
  cidr_block = "10.0.0.0/16" 
}

#creating first subnet
resource "aws_subnet" "sub1" {
  availability_zone = "us-east-1a"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet for us-east-1a"
  }
}

# creating second subnet 
resource "aws_subnet" "sub2" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet for us-east-1b"
  }
}

#creating security group
resource "aws_security_group" "amohsg" {
  name = "amohgroup"
  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port = 80
    to_port   = 80
     protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# creating ec2 instance
resource "aws_instance" "ubuntu" {
  ami           = "ami-0dba2cb6798deb6d8" # us-east-1
  instance_type = "t2.micro"
  tags = {
      Name = "myubuntu"
  }
}

# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "amingo-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [aws_instance.ubuntu.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "amingo-elb"
  }
}

#creating s3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "eating-bucket100"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.b.id

  block_public_acls   = false
  block_public_policy = false
}