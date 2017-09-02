log() {
	msg = $1
	echo $msg > log.file

}


#download some required files
echo "PREPARE ENVIRONMENT..."
apt-get update && apt-get install build-essential libtool automake libncurses5-dev kernel-package
echo "DOWNLOAD KERNEL SOURCE CODE..."
mkdir uml && cd uml
wget http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v4.x/testing/linux-4.9-rc5.tar.gz -O kernel.tar.gz && tar -xzf kernel.tar.gz
cd linux-4.9-rc5

#build kernel
echo "START BUILDING KERNEL SOURCE CODE..."
make defconfig ARCH=um
echo "MAKE DEFAULT CONFIG.."
echo "BUILDING START.."
make vmlinux ARCH=um
cp vmlinux ..
cd ..
echo "BUILDING FINISHED.."

#make rootfs
echo "INSTALL DEBOOTSTRAP.."
apt-get install debootstrap
echo "INSTALL FINISH"
echo "START BUILDING ROOT FILESYSTEM.."
fallocate -l 4G rootfs && mkfs.ext4 rootfs
mkdir mnt && mount rootfs mnt
debootstrap --arch amd64 xenial mnt/
echo "please use the command 'passwd' to set your root password theninput 'exit' to quit"
#gnome-terminal -t "set root password" -x bash -c "chroot mnt"
echo "/dev/ubda / ext4 defaults 0 0" > mnt/etc/fstab
wait 3
umount mnt

#run uml
apt-get install uml-utilities screen
vmlinux ubda=rootfs mem=256M con=pts con1=fd:0,fd:1

