## bridge-tap.service && setup-bridge-tap.sh

这两个脚本用于在开机时设置一个虚拟网桥，常用于物理机和qemu的虚拟机进行网络通信使用。

使用方法：将两个文件分别放置或编辑到以下位置，并赋予可执行权限。

- `/usr/local/bin/setup-bridge-tap.sh`

- `/etc/systemd/system/bridge-tap.service` 

然后重新加载服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable bridge-tap.service 
```

## proxy-man

快速的设置将本机网络环境变量，在一定程度上能解决某些软件不走代理的情况。

使用方法：将其放置在

- `/usr/local/bin/proxy-man`

使用以下指令使用

```bash
source proxy-man on|off
```
