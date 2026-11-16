data "aws_ami" "os_image" {
  owners      = ["099720109477"] # Canonical
  most_recent = true
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key-v2" 
  public_key = file("terra-key.pub")
}
resource "aws_security_group" "allow_user_to_connect" {
  name_prefix = "jenkins-sg-" 
  description = "Allow user to connect to Jenkins and SSH"
  
  # UNIFIED: Linked to your Custom VPC instead of the default VPC
  vpc_id      = module.vpc.vpc_id 
  
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

resource "aws_instance" "testinstance" {
  ami                    = data.aws_ami.os_image.id
  instance_type          = "m7i-flex.large" 
  key_name               = aws_key_pair.deployer.key_name
  
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]
  
  # UNIFIED: Deploys Jenkins directly into the first public subnet of your custom VPC
  subnet_id              = module.vpc.public_subnets[0]
  
  user_data              = replace(file("${path.module}/install_tools.sh"), "\r\n", "\n")
  
  tags = {
    Name = "Jenkins-Automate"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}