provider "aws" {
  region = "us-east-1"
}

# 1. Virtual Private Cloud (Network Layer)
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "devops-vpc" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                 = { Name = "devops-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_vpc.id
  tags   = { Name = "devops-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 2. Firewalls (Security Groups)
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Instance Profile mapping to your manually created role
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = "jenkins-admin-role" # Links to the role you created in the console
}

# 4. Compute Engine (Jenkins Server instance)
resource "aws_instance" "jenkins_server" {
  ami                  = "ami-0c7217cdde317cfec" 
  instance_type        = "t3.small"             
  subnet_id            = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  key_name             = "Jenkins_task" # Ensure you replace this with your active keypair name!

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install openjdk-17-jre -y
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://jenkins.io
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://jenkins.io binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              sudo apt-get install docker.io -y
              sudo usermod -aG docker jenkins
              sudo systemctl restart jenkins
              EOF

  tags = { Name = "Jenkins-Control-Plane" }
}

output "jenkins_public_ip" {
  value       = aws_instance.jenkins_server.public_ip
  description = "Connect to your automation controller dashboard here"
}
