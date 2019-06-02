#!/bin/bash
# IPChanger Script v0.1
# Written by iLemonrain <ilemonrain@ilemonrain.com> Version 20190602

# ===== 全局定义 =====
# 使用前请先修改以下参数
# DHCP操作网卡
interface_name="$(ip -4 route | awk -F' ' '/default/{print $5}')"
# 国内目标
blockcheck_chinatarget="www.baidu.com"
# 全局超时设置，如果3秒太短或者误判率太高可以适当调高此值
timeout="3"

# 字体颜色定义
Font_Black="\033[30m"  
Font_Red="\033[31m" 
Font_Green="\033[32m"  
Font_Yellow="\033[33m"  
Font_Blue="\033[34m"  
Font_Purple="\033[35m"  
Font_SkyBlue="\033[36m"  
Font_White="\033[37m" 
Font_Suffix="\033[0m"

# 消息提示定义
Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Blocked="${Font_Red}[Block] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Fail="${Font_Red}[Failed] ${Font_Suffix}"

# DHCP释放
Func_DHCPRelease() {
    apt install iproute net-tools -y
    dhclient -r "${interface_name}"
    rm -f /var/lib/dhclient/dhclient.leases
}

# DHCP申请
Func_DHCPLease() {
    dhclient "${interface_name}"
}

# 重启网络
Func_RestartNetwork() {
    ifconfig ${interface_name} down
    ifconfig ${interface_name} up
}

# 获取本机IP
Func_GetMyIP() {
    MyIP="$(curl --connect-timeout ${timeout} -s ip.sb)"
}

# 检查到国内是否ICMP墙
Func_CheckBlock_ChinaIP_ICMP() {
    ping -c 1 -w ${timeout} ${blockcheck_chinatarget} >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        CheckBlock_ChinaIP_ICMP_Blocked="1"
    else
        CheckBlock_ChinaIP_ICMP_Blocked="0"
    fi
}

# 检查到国内是否TCP墙
Func_CheckBlock_ChinaIP_TCP() {
    curl -s --connect-timeout ${timeout} ${blockcheck_chinatarget} >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        CheckBlock_ChinaIP_TCP_Blocked="1"
    else
        CheckBlock_ChinaIP_TCP_Blocked="0"
    fi
}

MainFunc() {
	Func_CheckBlock_ChinaIP_TCP
    if [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ] && [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ]; then
        echo -e "${Msg_Success}IP ${MyIP} 没有被阻断，可以正常使用 !"
		exit 100
	fi
    echo -e "${Msg_Info}正在释放${interface_name}上的当前IP ..."
    Func_DHCPRelease
    echo -e "${Msg_Info}正在重新启动${interface_name}网卡 ..."
    Func_RestartNetwork
    echo -e "${Msg_Info}正在申请${interface_name}上的IP ..."
    Func_DHCPLease
    echo -e "${Msg_Info}正在获取本机外网IP ..."
    Func_GetMyIP
    echo -e "${Msg_Info}正在检测 ${MyIP} 到国内ICMP可用性 ..."
    Func_CheckBlock_ChinaIP_ICMP
    echo -e "${Msg_Info}正在检测 ${MyIP} 到国内TCP可用性 ..."
    Func_CheckBlock_ChinaIP_TCP
    if [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ] && [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ]; then
        echo -e "${Msg_Success}IP ${MyIP} 没有被阻断，可以正常使用 !"
        CheckCode="101"
    elif [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "1" ] && [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ]; then
        echo -e "${Msg_Blocked}IP ${MyIP} 被阻断： ICMP: ${Font_Red}Yes${Font_Suffix} / TCP: ${Font_Green}No${Font_Suffix} "
        CheckCode="102"
    elif [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "0" ] && [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "1" ]; then
        echo -e "${Msg_Blocked}IP ${MyIP} 被阻断： ICMP: ${Font_Green}No${Font_Suffix} / TCP: ${Font_Red}Yes${Font_Suffix} "
        CheckCode="103"
    elif [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "1" ] && [ "${CheckBlock_ChinaIP_ICMP_Blocked}" = "1" ]; then
        echo -e "${Msg_Blocked}IP ${MyIP} 被阻断： ICMP: ${Font_Red}Yes${Font_Suffix} / TCP: ${Font_Red}Yes${Font_Suffix} "
        CheckCode="104"
    else
        echo -e "${Msg_Error}无法判断当前IP的情况! 把柠檬榨汁或许可能会解决此问题! "
        exit 100
    fi
    if [ "${CheckCode}" == "102" ] || [ "${CheckCode}" == "103" ] || [ "${CheckCode}" == "104" ]; then
        echo -e "${Msg_Info}正在重新开始IP申请流程"
        CheckCode="0" && MyIP="0.0.0.0"
        MainFunc
    else
        echo -e "${Msg_Success}已成功更换IP: ${MyIP}"
    fi
}

# 全局入口
MainFunc