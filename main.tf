# Create a VPC
resource "aws_vpc" "project7" {
  cidr_block = "10.0.0.0/16"
}

# Creating 2 subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.project7.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "subnet-1"
  }
}
resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.project7.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "subnet-2"
  }
}

# Creating 2 route table
resource "aws_route_table" "prj7-route-tabel1" {
  vpc_id = aws_vpc.project7.id

  route = []

  tags = {
    Name = "prj7-route-tabel1"
  }
}
resource "aws_route_table" "prj7-route-tabel2" {
  vpc_id = aws_vpc.project7.id

  route = []

  tags = {
    Name = "prj7-route-tabel2"
  }
}

# Creating internet gateway
resource "aws_internet_gateway" "prj7-igw" {
  vpc_id = aws_vpc.project7.id

  tags = {
    Name = "prj7-igw"
  }
}

resource "aws_route_table" "igw-rt" {
  vpc_id = "${aws_vpc.project7.id}"
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.prj7-igw.id}"
  }
}



# Route Table Association with subnet and internet Gateway
resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prj7-route-tabel1.id
  }
resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.prj7-route-tabel2.id
}

# Project Security Group
resource "aws_security_group" "prj7-sg" {
  name        = "prj7-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.project7.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.project7.cidr_block]
  }
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.project7.cidr_block]
  }
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.project7.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

  tags = {
    Name = "prj7-sg"
  }
}

# Webserver 1
resource "aws_network_interface" "WebServ-av1a" {
  subnet_id   = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.10"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "wb1" {
  ami           = "ami-0a654623d21580ce0" # eu-north-2
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.WebServ-av1a.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

# Webserver 2
resource "aws_network_interface" "WebServ-av1b" {
  subnet_id   = aws_subnet.subnet-2.id
  private_ips = ["10.0.2.10"]

  tags = {
    Name = "primary_network_interface2"
  }
}

resource "aws_instance" "wb2" {
  ami           = "ami-0a654623d21580ce0" # eu-north-2
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.WebServ-av1b.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

# Target group
resource "aws_lb_target_group" "prj7-tg" {
  name     = "prj7-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project7.id
}

# Creating a Netwrok Load balancer
resource "aws_lb" "prj7-nlb" {
  name               = "prj7-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            =  [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# Creating an Auto Sclaing Group
resource "aws_placement_group" "prj7-place" {
  name     = "prj7-place"
  strategy = "partition"
}

resource "aws_autoscaling_group" "prj7-group" {
  name                      = "project7-test"
  max_size                  = 1
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 0
  force_delete              = true
  placement_group           = aws_placement_group.prj7-place.id
  launch_configuration      = aws_launch_configuration.prj-lc.name
  vpc_zone_identifier       = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  initial_lifecycle_hook {
    name                 = "firsthook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING" 

   notification_metadata = <<EOF
{
  "prj7-place": "prj7-groupr"
}
EOF

    #notification_target_arn = "arn:aws:sqs:eu-north-1:444455556666:queue1*"
    #role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }

  tag {
    key                 = "prj7-place"
    value               = "prj7-group"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}

# Lunch Configuration
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

resource "aws_launch_configuration" "prj-lc" {
  name_prefix   = "prj-lc"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
  }
}

#Still Need some reall touch, i am strugling