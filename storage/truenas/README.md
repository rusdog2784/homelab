# Hardware Details
- CPU: 4 cores
- Memory: 16 GB
- CD/DVD Drive (ide2): `local:iso/TrueNAS-13.0-U6.7.iso,media=cdrom,size=1024606K`
- Hard Disk (scsi 0): `local-lvm:vm-101-disk-0,iothread=1,size=30G`
- Hard Disk (scsi 1): `/dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ325XH`
- Hard Disk (scsi 2): `/dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ32T1T`

# Helpful Commands
1. To assign a physical Hard Drive to a VM as an SCSI device:

	```bash
	# Command:
	qm set <vm-id> -scsi<index> <disk-by-id>

	# Example:
	qm set 200 -scsi1 /dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ325XH
	```
