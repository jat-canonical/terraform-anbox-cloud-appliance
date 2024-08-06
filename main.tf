data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-${var.architecture}-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "main" {}

data "aws_security_groups" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh-access-for-instances"
  description = "Allows SSH on instances from outside"
  vpc_id      = data.aws_vpc.main.id
  tags = {
    Name = "AnboxCloudAppliance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ssh.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_security_group" "appliance_ingress" {
  name        = "http-access-for-instances"
  description = "Allows HTTP Access on appliance"
  vpc_id      = data.aws_vpc.main.id
  tags = {
    Name = "AnboxCloudAppliance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gateway" {
  security_group_id = aws_security_group.appliance_ingress.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "ams" {
  security_group_id = aws_security_group.appliance_ingress.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 8444
  ip_protocol = "tcp"
  to_port     = 8444
}

resource "aws_vpc_security_group_ingress_rule" "ams_node_ports" {
  security_group_id = aws_security_group.appliance_ingress.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 10000
  ip_protocol = "tcp"
  to_port     = 11000
}

resource "aws_vpc_security_group_ingress_rule" "stun_tcp" {
  security_group_id = aws_security_group.appliance_ingress.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 5349
  ip_protocol = "tcp"
  to_port     = 5349
}

resource "aws_vpc_security_group_ingress_rule" "stun_udp" {
  security_group_id = aws_security_group.appliance_ingress.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port = 5349
  ip_protocol = "udp"
  to_port     = 5349
}

resource "aws_instance" "appliance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  user_data = templatefile("${path.module}/templates/cloudinit.tmpl", { ssh_import_ids = var.ssh_import_ids })
  vpc_security_group_ids = concat(data.aws_security_groups.default.ids, [aws_security_group.ssh.id, aws_security_group.appliance_ingress.id])

  tags = {
    Name = "AnboxCloudAppliance"
  }
}

resource "terraform_data" "setup_appliance" {
  input = aws_instance.appliance.public_ip
  connection {
    type = "ssh"
    user = "ubuntu"
    host = self.input
  }

  provisioner "remote-exec" {
    inline = [
      "sudo pro attach ${var.ua_token}",
      "sudo pro enable anbox-cloud --access-only",
      "sudo apt update && sudo apt install -y linux-modules-extra-$(uname -r)",
      "sudo snap install anbox-cloud-appliance --channel ${var.channel}",
      "sudo anbox-cloud-appliance init --auto",
      "sudo amc config set images.version_lockstep false"
    ]
  }
}

output "appliance" {
   value = "https://${aws_instance.appliance.public_dns}/"
}
