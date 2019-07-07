resource "aws_instance" "nodes01" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = "${var.vpc_security_group_ids}"
  key_name = "${var.key}"
  user_data = "${data.template_cloudinit_config.node_cloud_init.rendered}"
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
        "user_data"
    ]
  }

  tags = {
    Name = "Nodes 01"
  }
}

resource "aws_instance" "nodes02" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = "${var.vpc_security_group_ids}"
  key_name = "${var.key}"
  user_data = "${data.template_file.init_node.rendered}"          
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
        "user_data"
    ]
  }
  tags = {
    Name = "Nodes 02"
  }
}