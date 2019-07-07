output "master" {
    value = "${aws_eip.master.public_ip}"
}

output "nodes01" {
  value = "${aws_instance.nodes01.public_ip}"
}
output "nodes02" {
  value = "${aws_instance.nodes02.public_ip}"
}