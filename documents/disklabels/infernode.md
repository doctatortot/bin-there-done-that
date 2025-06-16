🟩 **Disk-to-Serial Mapping on ZFS VM (FreeBSD)**
=================================================

```shell
    1. Name: cd0
       Mediasize: 1310040064 (1.2G)
       descr: QEMU QEMU DVD-ROM
       ident: (null)

    1. Name: da0
       Mediasize: 268435456000 (250G)
       descr: QEMU QEMU HARDDISK
       ident: (null)

    1. Name: da1
       Mediasize: 10737418240000 (9.8T)
       descr: QEMU QEMU HARDDISK
       ident: (null)

    1. Name: da2
       Mediasize: 10737418240000 (9.8T)
       descr: QEMU QEMU HARDDISK
       ident: (null)

    1. Name: da3
       Mediasize: 34359738368 (32G)
       descr: QEMU QEMU HARDDISK
       ident: (null)

  pool: inferno
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	inferno     ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    da1     ONLINE       0     0     0
	    da2     ONLINE       0     0     0
	logs	
	  da3       ONLINE       0     0     0

errors: No known data errors

  pool: zroot
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	zroot       ONLINE       0     0     0
	  da0p3     ONLINE       0     0     0

errors: No known data errors
