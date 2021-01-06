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
  sudo ip netns add lan
  sudo ip netns add router
  sudo ip netns add wan
}

: "add-veth" && {
  sudo ip link add lan-veth0 type veth peer name gw-veth0
  sudo ip link add wan-veth0 type veth peer name gw-veth1
}

: "set-veth" && {
  sudo ip link set lan-veth0 netns lan
  sudo ip link set gw-veth0 netns router
  sudo ip link set gw-veth1 netns router
  sudo ip link set wan-veth0 netns wan
}

: "link-up" && {
  sudo ip netns exec lan ip link set lan-veth0 up
  sudo ip netns exec router ip link set gw-veth0 up
  sudo ip netns exec router ip link set gw-veth1 up
  sudo ip netns exec wan ip link set wan-veth0 up
}

: "setup-lan" && {
  sudo ip netns exec lan ip address add 192.0.2.1/24 dev lan-veth0
  sudo ip netns exec lan ip route add default via 192.0.2.254
}

: "setup-router" && {
  sudo ip netns exec router ip address add 192.0.2.254/24 dev gw-veth0
  sudo ip netns exec router ip address add 203.0.113.254/24 dev gw-veth1
  sudo ip netns exec router sysctl net.ipv4.ip_forward=1
}

: "setup-wan" && {
  sudo ip netns exec wan ip address add 203.0.113.1/24 dev wan-veth0
  sudo ip netns exec wan ip route add default via 203.0.113.254
}

: "add-snat-rule" && {
  sudo ip netns exec router iptables -t nat \
    -A POSTROUTING \
    -s 192.0.2.0/24 \
    -o gw-veth1 \
    -j MASQUERADE
}

: "add-dnat-rule" && {
  sudo ip netns exec router iptables -t nat \
    -A PREROUTING \
    -p tcp \
    --dport 54321 \
    -d 203.0.113.254 \
    -j DNAT \
    --to-destination 192.0.2.1
}

: "test" && {
  sudo ip netns exec lan ping -c 3 203.0.113.1
}

: "done" && {
  set +x
  echo "successful"
}