#!/bin/sh

# ======================
# author: thobian
# desc: vultr �»�����װss�ű�
# ======================

# �رշ���ǽ
echo "============================"
echo "close iptables...."
service iptables stop  
chkconfig iptables off  
echo "iptables closed...."
echo -e "============================\n"

# ��װss
echo "============================"
echo "install shadowsocks...."
yum install -y python-pip
pip install shadowsocks
echo "shadowsocks installed...."
echo -e "============================\n"


# ����ļ����λ��
CONFIG="/etc/shadowsocks.json"
LOG_PATH="/var/log/shadowsocks.log"

# д�����ļ�
# port_password ���־�����ss������Ҫ�����˿ڣ��Լ��ö˿ڶ�Ӧ������
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

# ����ss�����
echo "============================"
echo "start shadowsocks server...."
ssserver -c $CONFIG --log-file=$LOG_PATH -d start 
echo "started...."
echo "log:${LOG_PATH}"
echo -e "============================\n"