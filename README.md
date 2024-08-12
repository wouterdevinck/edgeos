# EdgeOS

Minimal Linux based OS running Docker on the Raspberry Pi 4 with robust A/B upgrade mechanism.

## Partitions

| RPI4 | PC | Type | Size | Name | Comments |
| --- | ---|--- | --- | --- | --- |
| 1 | n/a | FAT | 64 MB | AUTOBOOT | autoboot.txt |
| 2 | 1 | FAT | 256 MB | BOOT_A | Kernel, initramfs, firware, boot configuration |
| 3 | 2 | FAT | 256 MB | BOOT_B | |
| 4 | 3 | - | - | EXTENDED PARTITION | |
| 5 | 5 | SquashFS | 1 GB | ROOT_A | Root file system |
| 6 | 6 | SquashFS | 1 GB | ROOT_B | |
| 7 | 7 | SquashFS | 128 MB | MANIFEST_A | Manifest & compose file |
| 8 | 8 | SquashFS | 128 MB | MANIFEST_B | |
| 9 | 9 | Ext4 | 256 MB | CONFIG | Overlay on top of /etc |
| 10 | 10 | Ext4 | 1 GB | LOGS | Partition for logs |
| 11 | 11 | Ext4 | Rest of disk | DOCKER | Mounted as /var/lib/docker |

## Boot flow

TODO