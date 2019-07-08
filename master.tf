resource "aws_instance" "master" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.master_subnet_id}"
  vpc_security_group_ids = [
        "${aws_security_group.kubernetes.id}"
    ]  
  key_name = "${var.key}"
  user_data = "${data.template_cloudinit_config.master_cloud_init.rendered}"
  lifecycle {
    ignore_changes = [
      "ami",
      "user_data",
      "associate_public_ip_address"
      ]
    }
  tags = {
    Name = "Master"
  }
}
