data "template_file" "node-setup" {
  template = file("./user_data/cri-o/cluster-prereqs.sh")
}

resource "aws_network_interface" "k8s-worker-network-interfaces" {
  count     = var.node_count
  subnet_id = element(aws_subnet.cluster-vpc-subnets.*.id, count.index)
}

resource "aws_network_interface_sg_attachment" "k8s-worker-sg-attachment" {
  count                = var.node_count
  security_group_id    = aws_security_group.k8s-worker-sg.id
  network_interface_id = aws_instance.k8s-nodes[count.index].primary_network_interface_id
}

resource "aws_security_group" "k8s-worker-sg" {
  name        = "k8s-worker-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.cluster-vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # Here it is kept open for demo
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "k8s-worker-sg"
    }
  , local.tags)
}


resource "aws_instance" "k8s-nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = var.cluster_key_pair
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "15"
    delete_on_termination = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.k8s-worker-network-interfaces[count.index].id
  }

  user_data   = data.template_file.node-setup.rendered
  volume_tags = local.tags
  tags = merge({
    Name = "k8s-worker-node-${count.index}"
    }
  , local.tags)
}
