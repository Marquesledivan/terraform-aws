module "kubeadm-token" {
  source = "./terraform-kubeadm-token"
  
}

# Find VPC details based on Master subnet
data "aws_subnet" "cluster_subnet" {
  id = "${var.master_subnet_id}"
}

resource "aws_security_group" "kubernetes" {
  vpc_id = "${data.aws_subnet.cluster_subnet.vpc_id}"
  name = "${var.cluster_name}"
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_kubernetes" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.kubernetes.id}"
}

# Allow SSH connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_ssh_from_cidr" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.kubernetes.id}"
}

# Allow the security group members to talk with each other without restrictions
resource "aws_security_group_rule" "allow_cluster_crosstalk" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = "${aws_security_group.kubernetes.id}"
    security_group_id = "${aws_security_group.kubernetes.id}"
}

# Allow API connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_api_from_cidr" {
    type = "ingress"
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.kubernetes.id}"
    security_group_id = "${aws_security_group.kubernetes.id}"
}


resource "aws_eip_association" "master_assoc" {
  instance_id   = "${aws_instance.master.id}"
  allocation_id = "${aws_eip.master.id}"
}

resource "aws_eip" "master" {
  vpc      = true
}

data "template_file" "init_master" {
  template = "${file("${path.module}/scripts/master.sh")}"

  vars {
    kubeadm_token = "${module.kubeadm-token.token}"
    dns_name      = "ledivan.oi"
    ip_address    = "${aws_eip.master.public_ip}"
    aws_subnets = "${var.master_subnet_id}"
  }
}
data "template_file" "init_node" {
  template = "${file("${path.module}/scripts/node.sh")}"

  vars {
    kubeadm_token = "${module.kubeadm-token.token}"
    master_ip     = "${aws_eip.master.public_ip}"
    master_private_ip     = "${aws_instance.master.private_ip}"
  }
}

data "template_file" "cloud_init_config" {
    template = "${file("${path.module}/scripts/cloud-init-config.yaml")}"

    vars {
        calico_yaml = "${base64gzip("${file("${path.module}/scripts/calico.yaml")}")}"
    }
}

data "template_cloudinit_config" "master_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_init_config.rendered}"
  }

  part {
    filename     = "init-aws-kubernete-master.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.init_master.rendered}"
  }
}

data "template_cloudinit_config" "node_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "node.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.init_node.rendered}"
  }
}
