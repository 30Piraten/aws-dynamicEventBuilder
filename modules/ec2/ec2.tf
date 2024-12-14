data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = var.filter_name_one
    values = var.filter_values_one
  }

  filter {
    name   = var.filter_name_two
    values = var.filter_values_two
  }
}

resource "aws_instance" "vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    name = var.tag_name
  }
}