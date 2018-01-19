# run your admin openrc.sh first

### [General setup] ###
variable "external_gateway" {
  default = "77e7bded-b920-41c0-91b6-579c4a8e6b32"
}

#resource "openstack_compute_keypair_v2" "keypair" {
#  name = "aolwas-keypair"
#  public_key = "${file("~/.ssh.id_rsa_objectiflibre.pub")}"
#}

### Should be tighten up, not let the world be able to ssh
### this is only for demonstrational purposes.

resource "openstack_compute_secgroup_v2" "openbar_sg" {
  name = "testcluster-openbar-sg"
  description = "openbar security group"
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    cidr = "0.0.0.0/0"
  }
}

### [networking] ###
resource "openstack_networking_router_v2" "router" {
  name = "testcluster-router"
  admin_state_up = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_network_v2" "net" {
  name = "testcluster-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name = "testcluster-subnet"
  network_id = "${openstack_networking_network_v2.net.id}"
  cidr = "10.254.0.0/24"
  ip_version = 4
  enable_dhcp = "true"
}

resource "openstack_networking_router_interface_v2" "ext-interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet.id}"
}

### Instances ###

module "instance" {
  source = "../modules/instance"

  nb = 3
  name = "testcluster"
  image = "ubuntu-xenial-x64"
  flavor = "m2.small"
  keyPair = "mcottret"
  network = "testcluster-net"
  hasFloating = true
  securityGroups = ["default", "testcluster-openbar-sg"]
  userData = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce #=17.03.2~ce-0~ubuntu-xenial
sudo usermod -aG docker ubuntu
sudo curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
EOF
}


### outputs ###
output "Instance IDs" {
  value = "${module.instance.id}"
}

output "Instance Names" {
  value = "${module.instance.name}"
}

output "Private IP" {
  value = "${module.instance.private_ip}"
}

output "Floating IP" {
  value = "${module.instance.floating_ip}"
}

output "Volume IDs" {
  value = "${module.instance.volume_id}"
}
