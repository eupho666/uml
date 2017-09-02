## log file
function log() {
	msg = $1
	echo $msg >> log.txt

}

## green echo
function green(){
	echo -e "\033[32m\033[01m\033[05m[ $1 ]\033[0m"
	log $1
}

## error
function check() {
	if [ $? -eq 0]
	then
		log "$@ sucessed."
	else
		log "$@ failed."
		end_date = `date "+%Y-%m-%d %H:%M:%S"`
		log "end at : ${end_date}"
		log "==========END=========="
		exit 1
}

#download some required files
log "==========START=========="

date = `date "+%Y-%m-%d %H:%M:%S"`
user = `whoami`
log "${date} ${user} execute ..."

green "PREPARE ENVIRONMENT..."
apt-get update && apt-get install build-essential libtool automake libncurses5-dev kernel-package
green "PREPARE DONE"

green "DOWNLOAD KERNEL SOURCE CODE..."
mkdir uml && cd uml
wget http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v4.x/testing/linux-4.9-rc5.tar.gz -O kernel.tar.gz && tar -xzf kernel.tar.gz
cd linux-4.9-rc5

#build kernel
green "START BUILDING KERNEL SOURCE CODE..."

green "MAKE DEFAULT CONFIG.."
make defconfig ARCH=um

green "BUILDING START.."
make vmlinux ARCH=um

cp vmlinux ..
cd ..
green "BUILDING FINISHED.."

#make rootfs
green "INSTALL DEBOOTSTRAP.."
apt-get install debootstrap
green "INSTALL FINISH"

green "START BUILDING ROOT FILESYSTEM.."
fallocate -l 4G rootfs && mkfs.ext4 rootfs
mkdir mnt && mount rootfs mnt
debootstrap --arch amd64 xenial mnt/ >> log.txt
check "bootstrap"

green "please use the command 'passwd' to set your root password theninput 'exit' to quit"
chroot mnt

wait 1
echo "/dev/ubda / ext4 defaults 0 0" > mnt/etc/fstab
check "make fstab file"

wait 3
green "OMOUNTING..."
umount mnt
check "umount"

#run uml
apt-get install uml-utilities screen
green "SET UP UML"
vmlinux ubda=rootfs mem=256M con=pts con1=fd:0,fd:1
check "set up"
end_date = `date "+%Y-%m-%d %H:%M:%S"`
log "end at : ${end_date}"
log "==========END=========="
