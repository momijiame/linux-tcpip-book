#!/usr/bin/env bash

set -Ceuo pipefail

function error_handler() {
  set +x
  echo "something went wrong" >&2
  exit 1
}

: "start" && {
  echo "start building..."
  trap error_handler ERR
  set -x
}

: "add-netns" && {
  sudo ip netns add ns1
  sudo ip netns add router
  sudo ip netns add ns2
}

: "add-veth" && {
  sudo ip link add ns1-veth0 type veth peer name gw-veth0
  sudo ip link add ns2-veth0 type veth peer name gw-veth1
}

: "set-veth" && {
  sudo ip link set ns1-veth0 netns ns1
  sudo ip link set gw-veth0 netns router
  sudo ip link set gw-veth1 netns router
  sudo ip link set ns2-veth0 netns ns2
}

: "link-up" && {
  sudo ip netns exec ns1 ip link set ns1-veth0 up
  sudo ip netns exec router ip link set gw-veth0 up
  sudo ip netns exec router ip link set gw-veth1 up
  sudo ip netns exec ns2 ip link set ns2-veth0 up
}

: "add-ip" && {
  sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
  sudo ip netns exec router ip address add 192.0.2.254/24 dev gw-veth0
  sudo ip netns exec router ip address add 198.51.100.254/24 dev gw-veth1
  sudo ip netns exec ns2 ip address add 198.51.100.1/24 dev ns2-veth0
}

: "add-default-route" && {
  sudo ip netns exec ns1 ip route add default via 192.0.2.254
  sudo ip netns exec ns2 ip route add default via 198.51.100.254
}

: "to-be-router" && {
  sudo ip netns exec router sysctl net.ipv4.ip_forward=1
}

: "set-hw-addr" && {
  sudo ip netns exec ns1 ip link set dev ns1-veth0 address 00:00:5E:00:53:11
  sudo ip netns exec router ip link set dev gw-veth0 address 00:00:5E:00:53:12
  sudo ip netns exec router ip link set dev gw-veth1 address 00:00:5E:00:53:21
  sudo ip netns exec ns2 ip link set dev ns2-veth0 address 00:00:5E:00:53:22
}

: "test" && {
  sudo ip netns exec ns1 ping -c 3 198.51.100.1 -I 192.0.2.1
}

: "done" && {
  set +x
  echo "successful"
}