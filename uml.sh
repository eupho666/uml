#!/bin/bash
# author:eupho666


## green echo and log
green(){
	echo -e "\033[32m\033[01m\033[05m$1\033[0m"
	name=`pwd`
	if [ ${name:(-3):3} = "hhh" ]
	then
		echo $1 >> ../log.txt
	elif [ ${name:(-3):3} = "rc5" ]
	then
		echo $1 >> ../../log.txt
	else
		echo $1 >> log.txt
	fi
}

## error
check() {
	if [ $? -eq 0 ]
	then
		green "$@ sucessed."
	else
		green "$@ failed."
		end_date=`date "+%Y-%m-%d %H:%M:%S"`
		green "end at : ${end_date}"
		green "==========END=========="
		exit 1
	fi
}

# check permission
if [ $EUID != 0 ]
then
	echo "please run as root permission"
	exit 1
fi

# create log file
if [ -ne "log.txt"]
then
	touch log.txt
fi

# start
green "==========START=========="

date=`date "+%Y-%m-%d %H:%M:%S"`
user=`whoami`
green "${date} ${user} execute ..."

#download some required files
green "[*]PREPARE ENVIRONMENT..."
apt-get update && apt-get install build-essential libtool automake libncurses5-dev kernel-package | tee -a log.txt
green "[*]PREPARE DONE"

green "[*]DOWNLOAD KERNEL SOURCE CODE..."
mkdir uml-hhh && cd uml-hhh
wget http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v4.x/testing/linux-4.9-rc5.tar.gz -O kernel.tar.gz
tar -xzvf kernel.tar.gz
cd linux-4.9-rc5

#build kernel
green "[*]START BUILDING KERNEL SOURCE CODE..."

green "[*]MAKE DEFAULT CONFIG.."
make defconfig ARCH=um

green "[*]BUILDING START.."
make vmlinux ARCH=um | tee -a ../../log.txt

cp vmlinux ..
cd ..
green "[*]BUILDING FINISHED.."

#make rootfs
green "[*]INSTALL DEBOOTSTRAP.."
apt-get install debootstrap | tee -a ../log.txt
green "[*]INSTALL FINISH"

green "[*]START BUILDING ROOT FILESYSTEM.."
fallocate -l 4G rootfs && mkfs.ext4 rootfs
mkdir mnt && mount rootfs mnt
debootstrap --arch amd64 xenial mnt/ | tee -a ../log.txt
check "bootstrap"

green "[*]please use the command 'passwd' to set your root password theninput 'exit' to quit"
chroot mnt

wait 1
echo "/dev/ubda / ext4 defaults 0 0" > mnt/etc/fstab
check "make fstab file"

wait 3
green "[*]UMOUNTING..."
umount mnt
check "[*]umount"

#run uml
apt-get install uml-utilities screen
green "[*]SET UP UML"
./vmlinux ubda=rootfs mem=256M con=pts con1=fd:0,fd:1 | tee -a ../log.txt
check "set up"
rm -rf kernel.tar.gz
end_date=`date "+%Y-%m-%d %H:%M:%S"`
green "end at : ${end_date}"
green "==========END=========="
