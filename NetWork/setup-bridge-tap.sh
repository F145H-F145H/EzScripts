#!/bin/bash
# 创建网桥
brctl addbr ms_br
ip link set ms_br up
ip addr add 192.168.10.1/24 dev ms_br

# 创建并连接TAP设备
ip tuntap add dev ms_tap mode tap
brctl addif ms_br ms_tap
ip link set ms_tap up
ip addr add 192.168.10.100/24 dev ms_tap
