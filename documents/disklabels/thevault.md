🟩 **ZFS Disk & Partition Mapper (Linux)**
==========================================

🔧 **ZFS Pools and Devices:**
```shell
  pool: backups
 state: ONLINE
  scan: scrub repaired 0B in 00:00:02 with 0 errors on Fri May 30 14:55:04 2025
config:

	NAME        STATE     READ WRITE CKSUM
	backups     ONLINE       0     0     0
	  sdb       ONLINE       0     0     0

errors: No known data errors

lrwxrwxrwx 1 root root  9 May 17 23:31 ata-QEMU_DVD-ROM_QM00003 -> ../../sr0
lrwxrwxrwx 1 root root  9 May 17 23:31 scsi-0QEMU_QEMU_DVD-ROM_QM00003 -> ../../sr0
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part3 -> ../../sda3
lrwxrwxrwx 1 root root  9 May 17 23:31 scsi-1ATA_QEMU_DVD-ROM_QM00003 -> ../../sr0
lrwxrwxrwx 1 root root 10 May 18 00:06 scsi-1NAC85FXJ-part1 -> ../../sdb1
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-1NAC85FXJ-part9 -> ../../sdb9
lrwxrwxrwx 1 root root 10 May 18 00:06 scsi-33e4143383546584a-part1 -> ../../sdb1
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-33e4143383546584a-part9 -> ../../sdb9
lrwxrwxrwx 1 root root 10 May 18 00:06 scsi-SSeagate_Expansion_SW_00000000NAC85FXJ-part1 -> ../../sdb1
lrwxrwxrwx 1 root root 10 May 17 23:31 scsi-SSeagate_Expansion_SW_00000000NAC85FXJ-part9 -> ../../sdb9

NAME   TYPE   SIZE MOUNTPOINT                SERIAL               MODEL
loop0  loop 104.5M /snap/core/17210                               
loop1  loop 104.2M /snap/core/17200                               
loop2  loop  55.4M /snap/core18/2846                              
loop3  loop  88.9M /snap/plexmediaserver/484                      
loop4  loop  63.8M /snap/core20/2571                              
loop5  loop  55.4M /snap/core18/2855                              
loop7  loop  73.9M /snap/core22/1963                              
loop8  loop    87M /snap/lxd/29351                                
loop9  loop  89.4M /snap/lxd/31333                                
loop10 loop  73.9M /snap/core22/1981                              
loop11 loop  63.8M /snap/core20/2582                              
loop12 loop  44.4M /snap/snapd/23771                              
loop13 loop  50.9M /snap/snapd/24505                              
loop14 loop  88.9M /snap/plexmediaserver/480                      
sda    disk   140G                           drive-scsi0          QEMU HARDDISK
├─sda1 part     1M                                                
├─sda2 part     2G                                                
└─sda3 part   138G /                                              
sdb    disk   7.3T                           00000000NAC85FXJ     Expansion SW
├─sdb1 part   7.3T                                                
└─sdb9 part     8M                                                
sr0    rom    1.4G                           QEMU_DVD-ROM_QM00003 QEMU DVD-ROM
