provider "panos" {
    hostname = "127.0.0.1"
    username = "terraform"
    password = "secret"
}

resource "panos_management_profile" "mp1" {
    name = "Allow ping"
    ping = true
}

resource "panos_ethernet_interface" "eth1" {
    name = "ethernet1/1"
    comment = "Internal interface"
    management_profile = "${panos_management_profile.mp1.name}"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
    create_dhcp_default_route = true
}

resource "panos_ethernet_interface" "eth2" {
    name = "ethernet1/2"
    comment = "External interface"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
}

resource "panos_zone" "intZone" {
    name = "L3-trust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.eth1.name}"]
}

resource "panos_zone" "extZone" {
    name = "L3-untrust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.eth2.name}"]
}