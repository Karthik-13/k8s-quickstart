data "template_file" "master-setup" {
  template = file("./user_data/cri-o/master-setup.sh")
}

resource "aws_security_group" "k8s-master-sg" {
  name        = "k8s-master-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.cluster-vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # Here the port is kept open for the sake of demonstration
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s-worker-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "k8s-master-sg"
    }
  , local.tags)
}

resource "aws_network_interface" "k8s-master-network-interface" {
  subnet_id = element(aws_subnet.cluster-vpc-subnets.*.id, 0)
}

resource "aws_network_interface_sg_attachment" "k8s-master-sg-attachment" {
  security_group_id    = aws_security_group.k8s-master-sg.id
  network_interface_id = aws_instance.k8s-master.primary_network_interface_id
}

resource "aws_instance" "k8s-master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.cluster_key_pair
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "15"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.k8s-master-network-interface.id
    device_index         = 0
  }

  vpc_security_group_ids = [aws_security_group.k8s-master-sg.id]
  user_data              = data.template_file.master-setup.rendered
  volume_tags            = local.tags
  tags = merge({
    Name = "k8s-master"
    },
  local.tags)
}