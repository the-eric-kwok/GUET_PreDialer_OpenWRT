## 前言

众所周知，桂电的运营商网络需要一个奇葩的出校器才能连接，这让日常使用 Windows 和 Linux 的我很是不爽，原本想着自己抓包做一个，没想到师大已经有一位前辈先行完成了这个工作，他的 GitHub 项目地址为 https://github.com/xuzhipengnt/ipclient_gxnu

我根据他的 macopen.sh 脚本修改制作了一个可以在 OpenWRT 上每天自动拨号的版本，现在发布出来造福人类

## 依赖

1. bash

2. socat

3. uci (OpenWRT自带，其他路由器系统没用过，请自己解决这个问题)

## 第一步 安装依赖

首先呢，既然是要安装包，我们当然是要联网啦，我不管你用什么方式联网，插网线也好，用手机热点也好，这里限于篇幅，不展开讲了。

然后我们用电脑插网线连路由器（不推荐使用 WLAN 因为不够稳定），然后使用诸如 putty 或 OpenSSH 一类的工具来ssh路由器，具体操作也不细讲。

接下来，我们在路由器上运行这两个命令：

`opkg update`

`opkg install bash socat`

没有报错信息的话就是成功了，我们可以测试一下

```bash
# bash --version
GNU bash, version 4.3.42(1)-release (mips-openwrt-linux-gnu)
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>

This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

```

```bash
# socat -V
socat by Gerhard Rieger - see www.dest-unreach.org
socat version 1.7.3.1 on Aug 31 2018 01:29:48
   running on Linux version #0 Mon Feb 20 17:13:44 2017, release 4.4.50, machine mips
```

类似这样的输出就是完全OK的了。

好了，现在可以关掉手机热点了。

## 第二步 定制脚本

我们将我们的脚本copy到路由器上，vi 都会用吧，不会的话就 `opkg install nano` 装一个nano编辑器。

修改脚本的 `$server` 为学校的服务器，桂电的是 `172.16.1.1`，师大的是 `202.193.160.123`

并且将 `$isp` 修改为你的运营商对应的数字（1：联通，2：电信，3：移动）

然后在 username 和 password 那里输入你的宽带用户名和密码

vi 的话输入 `:wq` 保存退出，nano 的话按 `Ctrl+O` 键保存，然后 `Ctrl+X` 退出


## 第三步 测试是否可以连接

`chmod +x dial.sh` 这一步是给脚本加上可执行权限

`./dial.sh` 或 `bash dial.sh`

若输出类似于这样

```
********MacOpen Tool(For Shell)********
Switching to DHCP
Server: 172.16.1.1
MAC Address: xx:xx:xx:xx:xx:xx
Local IP Address: xx.xx.xx.xx
ISP Vendor Signature: 02
=========================================
\x61\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

Dialing PPPoE...

OK...All done!!
```

并且你发现电脑可以上网了，那就证明成功了。我们还差最后一步就完成了！

## 第四步 创建计划任务和自启动

`crontab -e` 编辑计划任务，内容为

```
0 7 * * * /root/dial.sh > /var/log/dial.log 2>&1
```

即，每天早上7点整雷打不动地自动拨号，并将日志存入`/var/log/dial.log`，只存储一天，第二天会把昨天的日志刷掉。

然后 `nano /etc/rc.local` 编辑自启动，内容为

```bash
/root/dial.sh
```

大功告成！享受你的自动拨号路由器吧！
## 运行效果截图
![运行效果截图](https://tuchuang001.com/images/2018/10/13/TIM20181013143827.png)
