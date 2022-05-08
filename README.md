# OpenKizOS

This project aims to provide an alternate operating system on Kizbox devices based on AT91 SoCs (TaHoma, CozyTouch, etc.).

Booting Linux on a Kizbox requires several bricks:

* Second-level bootloader to initialize RAM: at91-bootstrap
* Third-level bootloader to configure Linux environment (Device Tree and boot command line): u-boot-at91
* Kernel: mainline Linux
* Rootfs for the Kernel: using buildroot
* (optional): USB key Kernel and rootfs (could be launched from u-boot or Linux)

# Installing the images

Precompiled binaries are provided in the release tab. To install them on your Kizbox, you will need the SAM-BA utility. Instructions to get and use it are available on Microhip's website: https://www.microchip.com/DevelopmentTools/ProductDetails/PartNO/SAM-BA%20In-system%20Programmer

To boot the Kizbox into recovery mode, you will have to send 3.3V into the chip enable pin of the NAND flash. See https://github.com/Aldohrs/tahoma-jailbreak/blob/main/doc/Jailbreak.md for details on the TaHoma.

When set up with SAM-BA, your USB A-to-A and the Kizbox in recovery mode, send the firmware using the SAM-BA command utility (you may want to backup the original firmware before, see the article mentioned above for details):

```bash
sudo ./sam-ba -p serial -b sama5d3-xplained -a nandflash:::0xc0902405 -c erase -c writeboot:at91bootstrap.bin -c write:u-boot.bin:0x40000 -c write:u-boot-env.bin:0x100000 -c write:u-boot-env.bin:0x140000 -c write:linux.itb:0x180000 -c write:rootfs.ubi:0x800000
```

Reboot you Kizbox. On a TaHoma, green LEDs should power up at the end ofthe boot process. It should be reachable on your network using SSH and the credentials root/toor.

# Building the project

## Prepare the environment

First of all, you need a cross-compile environment for ARMv7. To install it, refer to your distribution's documentation. For example, under Debian-like distributions:

```bash
sudo apt-get install gcc-arm-linux-gnueabi
export CROSS_COMPILE=arm-linux-gnueabi- #This command has to be entered each time you start a new terminal
```

Clone this repository and initialize sub-modules:

```bash
git clone --recurse-submodules https://github.com/Aldohrs/openkizos
```

Go to https://buildroot.org/download.html and download the latest tarball. Uncompress it in the project folder.

To construct images and environment files for u-boot, you will need utilities for u-boot. Under Debian-like distros, you can install them with the package `u-boot-tools`.

## Compile the bootstrap

Copy the defconfig file for at91bootstrap:

```bash
cp openkizos/at91bootstrap/kizboxnf_uboot_defconfig at91bootstrap/configs/
```

Then configure and compile the bootstrap:

```bash
cd at91bootstrap
make kizboxnf_uboot_defconfig
make
```

## U-boot

The tag u-boot-2021.04-at91 has been proven to work, so you can checkout this tag in the u-boot-at91 submodule:

```bash
cd u-boot-at91
git checkout u-boot-2021.04-at91
```

From the root of the project, copy the u-boot defconfig and special DTS files:

```bash
cp openkizos/u-boot/at91-kizbox2-2.dts u-boot-at91/arch/arm/dts/
cp openkizos/u-boot/at91-kizbox2-common.dtsi u-boot-at91/arch/arm/dts/
cp openkizos/u-boot/kizbox2_nandflash_defconfig u-boot-at91/configs
cp openkizos/u-boot/Makefile u-boot-at91/arch/arm/dts/
```

Go back to the u-boot-at91 folder and run:

```bash
make kizbox2_nandflash_defconfig
make
```

## Kernel

Now it is time to compile Linux. Linux v5.4 has been tested with success so let's do that:

```bash
cd linux
git checkout v5.4
cd ..
cp openkizos/linux/kizbox2_defconfig linux/arch/arm/configs/
cp openkizos/linux/Makefile linux/arch/arm/boot/dts
cp openkizos/linux/sama5d3.dtsi linux/arch/arm/boot/dts
cp openkizos/linux/sama5d3_uart.dtsi linux/arch/arm/boot/dts
cp openkizos/linux/at91-kizbox2-2.dts linux/arch/arm/boot/dts
cp openkizos/linux/at91-kizbox2-common.dtsi linux/arch/arm/boot/dts
cd linux
make ARCH=arm kizbox2_defconfig
make ARCH=arm
make ARCH=arm dtbs
```

Note: if you're using GCC 10, you may encounter an error early in the compilation. In this case, follow the instructions here to get through: https://github.com/BPI-SINOVOIP/BPI-M4-bsp/issues/4

## Rootfs

We can create a minimal rootfs using buildroot.

After uncompressing buildroot, copy the following files into you buildroot folder:

```bash
cp openkizos/buildroot/overkiz_kizbox_defconfig buildroot/configs
cp -R openkizos/buildroot/custom_files buildroot/
```

Create the configuration:

```bash
cd buildroot
make overkiz_kizbox_defconfig
```

It is recommended to check for the Rootfs overlay path parameter in the menuconfig under the system configuration menu. You can also customize the tools you want to have in the target rootfs by selecting the packages (but remember you only have 128MB of NAND on a TaHoma):

```bash
make menuconfig
make busybox_config
```

If you want to set a custom MAC address for the Ethernet interface, modify the custom_files/etc/ethmac file with your own address. By default it will be set to `F8:81:1A:DE:AD:BE`.

When you feel ready, compile the rootfs. Note that the first time you compile it, a lot of time will be needed to complete so go take a coffee:

```bash
make
```

## Putting all together and flashing it to the NAND

When you're happy with your build, run the copytobuild.sh script. It will copy all relevant files and will compile the u-boot env and the Linux ITB necessary to enable u-boot to run Linux.

Then follow the steps described in the install section above to deploy the images.

# TODO

At the moment, only a device tree for the TaHoma v2 with 2 heads is available. Device trees for other Kizbox such as the Kizbox mini are available in the Kernel source code but changes similar to the ones made on the custom Device Tree are likely required for Linux to boot.
