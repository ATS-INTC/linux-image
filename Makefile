
CROSS_COMPILE=riscv64-unknown-linux-gnu-
ROOTFS=buildroot/output/images/rootfs.cpio
LINUX_IMG=linux-xlnx/arch/riscv/boot/Image
OPENSBI_DIR = opensbi
PLATFORM = axu15eg
OPENSBI_OBJMK = $(OPENSBI_DIR)/platform/$(PLATFORM)/objects.mk
FW_PAYLOAD = $(OPENSBI_DIR)/build/platform/$(PLATFORM)/firmware/fw_payload.bin
DTB=rocketchip-axu15eg.dtb

clean:
	cd buildroot && make clean
	cd linux-xlnx && make mrproper

rootfs:
	cd buildroot && cp ../.buildrootconfig .config && make CROSS_COMPILE=$(CROSS_COMPILE) -j8
	cp $(ROOTFS) .

linux: $(ROOTFS)
	cd linux-xlnx && cp ../.linuxconfig .config && make ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) -j8
	cp $(LINUX_IMG) .

dts:
	dtc -I dts -O dtb rocketchip-axu15eg.dts -o $(DTB)

opensbi: $(LINUX_IMG) dts
	sed -i "/FW_PAYLOAD_PATH=/d" $(OPENSBI_OBJMK)
	sed -i "/FW_FDT_PATH=/d" $(OPENSBI_OBJMK)
	sed -i "/FW_PAYLOAD_FDT_ADDR=/d" $(OPENSBI_OBJMK)
	echo "FW_FDT_PATH=../$(DTB)" >> $(OPENSBI_OBJMK)
	echo "FW_PAYLOAD_PATH=../Image" >> $(OPENSBI_OBJMK)
	echo "FW_PAYLOAD_FDT_ADDR=0x82200000" >> $(OPENSBI_OBJMK)
	make -C opensbi PLATFORM=$(PLATFORM) CROSS_COMPILE=$(CROSS_COMPILE)

qemu: $(FW_PAYLOAD)
	qemu-system-riscv64 -m 128M -smp 4 -machine virt -nographic -bios default -kernel /home/zfl/ats-intc/linux-image/linux-xlnx/arch/riscv/boot/Image