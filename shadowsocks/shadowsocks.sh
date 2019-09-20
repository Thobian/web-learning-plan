#!/bin/sh

# ======================
# author: thobian
# desc: vultr 新机器安装ss脚本
# ======================

# 关闭防火墙
echo "============================"
echo "close iptables...."
service iptables stop  
chkconfig iptables off  
echo "iptables closed...."
echo -e "============================\n"

# 安装ss
echo "============================"
echo "install shadowsocks...."
yum install -y python-pip
pip install shadowsocks
echo "shadowsocks installed...."
echo -e "============================\n"


# 相关文件存放位置
CONFIG="/etc/shadowsocks.json"
LOG_PATH="/var/log/shadowsocks.log"

# 写配置文件
# port_password 部分就是你ss服务器要监听端口，以及该端口对应的密码
echo "============================"
echo "write shadowsock config file...."
IP=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 | awk '{print $2}'|tr -d "addr:"`
echo "{
 \"server\":\"${IP}\",
 \"port_password\":{
    \"8880\":\"password1\",
    \"8881\":\"password2\",
    \"8882\":\"password3\"
 },
 \"timeout\":300,
 \"method\":\"aes-256-cfb\",
 \"fast_open\": false
}" > $CONFIG
echo "shadowsocks installed...."
echo -e "============================\n"

# 启动ss服务端
echo "============================"
echo "start shadowsocks server...."
ssserver -c $CONFIG --log-file=$LOG_PATH -d start 
echo "started...."
echo "log:${LOG_PATH}"
echo -e "============================\n"