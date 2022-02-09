#WEB SERVER FOR ANY REGION WITH LOAD BALANCER

provider "aws" {
  region = "eu-north-1"
}


resource "aws_security_group" "SG" {
  name = "SG with dynamic blocks"

  dynamic "ingress" {
    for_each = ["22", "80", "443"]
    content{
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security Group for WEB"
  }
}


resource "aws_launch_configuration" "web" {
  name_prefix = "WebServer-"
  image_id      = "${data.aws_ami.latest_amazon_linux.id}"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.SG.id]

  user_data = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web" {
  name = "AASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size = 2
  max_size = 2
  min_elb_capacity = 2
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  health_check_type = "ELB"
  load_balancers = [aws_elb.ELB.name]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "ELB" {
  name = "WebServer-ELB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups = [aws_security_group.SG.id]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3 
    target = "HTTP:80/"
    interval = 10
  }
  
  tags = {
     Name = "ELB for WEB-Server"
  }
}


resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone =  data.aws_availability_zones.available.names[1]
}