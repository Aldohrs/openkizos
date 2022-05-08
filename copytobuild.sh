cp at91bootstrap/build/binaries/at91bootstrap.bin build/
cp u-boot-at91/u-boot.bin build/
cp linux/arch/arm/boot/zImage build/
cp buildroot/output/images/rootfs.ubi build/
mkimage -f openkizos/linux/linux.its build/linux.itb
mkenvimage -r -s 0x20000 -o build/u-boot-env.bin openkizos/u-boot/u-boot.env
