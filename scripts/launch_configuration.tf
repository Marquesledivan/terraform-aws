resource "aws_launch_configuration" "gtw-orders-docker" {
  name_prefix     = "gtw-orders-docker"
  image_id        = "${data.aws_ami.ec2-linux.id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key}"
  security_groups = [
      "${aws_security_group.kubernetes.id}"
  ] 
  iam_instance_profile = "${aws_iam_instance_profile.InstanceProfile-gtw-orders-docker.id}"

  user_data = "${data.template_cloudinit_config.node_cloud_init.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}
