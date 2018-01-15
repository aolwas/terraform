### Variable ###

variable "nb" {
  default = 1
}

variable "name" {}

variable "image" {}

variable "flavor" {}

variable "network" {}

variable "keyPair" {}

variable "securityGroups" {
  type = "list"
}

variable "hasFloating" {
  default = false
}

variable "floatingPool" {
  default = "public"
}

variable "hasAdditionalVolume" {
  default = false
}

variable "volumeSize" {
  default = 10
}

variable "userData" {
  default = ""
}

### Resources ###

resource "openstack_compute_instance_v2" "instance" {
  name =  "${var.name}-${count.index}"
  count = "${var.nb}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  network = {
    name = "${var.network}"
  }
  key_pair = "${var.keyPair}"
  security_groups = ["${var.securityGroups}"]
  user_data = "${var.userData}"
}

resource "openstack_compute_floatingip_v2" "fip" {
  count = "${var.hasFloating ? var.nb : 0}"
  pool = "${var.floatingPool}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  count = "${var.hasFloating ? var.nb : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.fip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
}

resource "openstack_blockstorage_volume_v2" "registry_volume" {
  count = "${var.hasAdditionalVolume ? var.nb : 0}"
  name = "${var.name}-${var.nb}-volume"
  size = "${var.volumeSize}"
}

resource "openstack_compute_volume_attach_v2" "registry_va" {
  count = "${var.hasAdditionalVolume ? var.nb : 0}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id,count.index)}"
  volume_id   = "${openstack_blockstorage_volume_v2.registry_volume.*.id}"
}

output "id" {
  value = "${join(",", openstack_compute_instance_v2.instance.*.id)}"
}

output "private_ip" {
  value = "${join(",", openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4)}"
}

output "floating_ip" {
  value = "${join(",", openstack_compute_floatingip_v2.fip.*.address)}"
}

output "volume_id" {
  value = "${join(",", openstack_blockstorage_volume_v2.registry_volume.*.id)}"
}
