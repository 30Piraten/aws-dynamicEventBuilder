data "aws_ami" "amazon_linux" {
  most_recent = true 

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}



resource "aws_instance" "vm" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = {
    name = var.tag_name
    TTL = var.ttl_expiry_time
    Environment = var.environment
  }
}