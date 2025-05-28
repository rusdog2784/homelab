# GPU Passthrough to Debian 12 VM
Followed this [guide](https://medium.com/@cactusmccoy/gpu-access-from-a-virtual-machine-on-proxmox-server-ubuntu-vm-903bb9783cb3), but for the short, condensed version, check out the following steps.


## GRUB Parameters Configuration
1. `nano /etc/default/grub`

2. Update the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` in the file to this:
	- If Intel: `GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"`
	- If AMD: `GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"`

3. `update-grub`

4. Verify IOMMU is setup properly with `dmesg | grep -e DMAR -e IOMMU`
	- You should see something like this:
		```
		[    1.219719] AMD-Vi: Found IOMMU at 0000:00:00.2 cap 0x40

		[    0.000000] DMAR: IOMMU enabled
		```


## Virtual Function I/O (VFIO) Configuration
1. `nano /etc/modules`

2. Add the following commands to the file:
	```
	vfio
	vfio_iommu_type1
	vfio_pci
	vfio_virqfd
	```

3. `echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf`

4. `echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf`


## Blacklisting the drivers
1. `nano /etc/modprobe.d/blacklist.conf`

2. Add the following commands to the file:
	```
	# AMD GPUs
	blacklist amdgpu
	blacklist radeon
	# NVIDIA GPUs
	blacklist nouveau
	blacklist nvidia*
	# Intel GPUs
	blacklist i915
	```

3. `update-initramfs -u`


## GPU to the VFIO Settings
1. `lspci -v`
	- Locate your your GPU decimal/id (e.g., my NVIDIA is located at 01:00.0)

2. `lspci -n -s <your GPU decimal/id without the last decimal>` (e.g., `lspci -n -s 01:00`)
	- Example output:
		```
		01:00.0 0300: 10de:1b81 (rev a1)
		01:00.1 0403: 10de:10f0 (rev a1)
		```
	- The `10de:...` are the Vendor IDs. We'll need those in the next command.

3. `echo "options vfio-pci ids=<Vendor ID #1>, <Vendor ID #2>" > /etc/modprobe.d/vfio.conf` (e.g., `echo "options vfio-pci ids=10de:1b81, 10de:10f0" > /etc/modprobe.d/vfio.conf`)


## Create and Configure the Debian 12 VM for GPU Passthrough
1. Create a Debian 12 VM with the following main properties:
	- Machine: Defaul (i440fx)
	- SCSI Controller: VirtIO SCSI single
	- BIOS: OVMF (UEFI)
	- CPU: >= 1 core
	- Memory: >= 2 GB

2. Start the VM and run initial configuration/setup (i.e., change password, update hostname, network config, etc.)

3. Stop the VM.

4. In the Proxmox Hardware section of the VM, add a new PCI device.
	- Select "Raw Device"
	- Search for and select your GPU
	- Select "All Functions" checkbox
	- Click "Add"

5. In Proxmox Host shell, modify the VM's config: `nano /etc/pve/qemu-server/(VMID).conf`

6. Update the line starting with `hostpci0: 01:00` (or whatever your GPU decimal/id is) in the file to this: `hostpci0: 01:00,x-vga=on`
	- `x-vga=on` is optional since this configuration sometimes breaks the booting process. If you cannot boot the VM after adding these parameters, come back and delete the x-vga option.

7. Start the VM (if it doesn't fail, then refer back to step 6).

### Nvidia Configuration on VM
In the VM, execute the following commands for the Nvidia Configuration.

1. `bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"`

2. `bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"`

3. `update-initramfs -u`

### Grub Configuration on VM
In the VM, execute the following commands to update the Grub configuration.

1. `nano /etc/default/grub`

2. Update the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` in the file to this: `GRUB_CMDLINE_LINUX_DEFAULT="nomodeset quiet splash"`

3. `update-grub`

### Last Bit of Specific Code on VM
In the VM, execute the following commands to add the last configuration code.

1. `nano /etc/rc.local`

2. Copy and paste the following:
	```bash
	#!/bin/bash

	/sbin/modprobe nvidia

	if [ "$?" -eq 0 ]; then

	# Count the number of NVIDIA controllers found.
	N3D=`/lspci | grep -i NVIDIA | grep "3D controller" | wc -l`
	NVGA=`lspci | grep -i NVIDIA | grep "VGA compatible controller" | wc -l`

	N=`expr $N3D + $NVGA - 1`
	for i in `seq 0 $N`; do
	mknod -m 666 /dev/nvidia$i c 195 $i;
	done

	mknod -m 666 /dev/nvidiactl c 195 255

	else
	exit 1
	fi

	exit 0
	```

3. Reboot the VM: `reboot now`

### Install Nvidia Drivers
In the VM, execute the following commands to install the Nvidia drivers. Followed these steps: https://wiki.debian.org/NvidiaGraphicsDrivers#Debian_12_.22Bookworm.22

1. `echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list`

2. `apt update`

3. `apt install linux-headers-amd64`

4. Install the Nvidia Drivers depending on if you want:
	- to install "proprietary" flavor: `apt install nvidia-driver firmware-misc-nonfree`
	- to install "open" flavor (newer GPUs): `apt install nvidia-open-kernel-dkms nvidia-driver firmware-misc-nonfree`

5. `reboot now`

### Install Nvidia Container Toolkit
In the VM, follow the following instructions to install the Nvidia Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

Once installed, configure the Nvidia Container Toolkit:

1. `nvidia-ctk runtime configure --runtime=docker`

2. `systemctl restart docker`

3. (optional) To test the GPU integration: `docker run --gpus all nvidia/cuda:11.5.2-base-ubuntu20.04 nvidia-smi`


## Helpful Commands
- Monitor GPU usage in real-time: `watch -n 0.5 nvidia-smi`