module "kubeadm-token" {
  source = "./terraform-kubeadm-token"
  
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
    filename     = "master.sh"
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
