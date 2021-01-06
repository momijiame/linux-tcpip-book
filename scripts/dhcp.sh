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
  sudo ip netns add server
  sudo ip netns add client
}

: "add-veth" && {
  sudo ip link add s-veth0 type veth peer name c-veth0
}

: "set-veth" && {
  sudo ip link set s-veth0 netns server
  sudo ip link set c-veth0 netns client
}

: "set-hw-addr" && {
  sudo ip netns exec server ip link set dev s-veth0 address 00:00:5E:00:53:01
  sudo ip netns exec client ip link set dev c-veth0 address 00:00:5E:00:53:02
}

: "link-up" && {
  sudo ip netns exec server ip link set s-veth0 up
  sudo ip netns exec client ip link set c-veth0 up
}

: "add-ip" && {
  sudo ip netns exec server ip address add 192.0.2.254/24 dev s-veth0
}

: "done" && {
  set +x
  echo "successful"
}