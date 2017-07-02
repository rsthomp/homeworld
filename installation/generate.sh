#!/bin/bash
set -e -u
if [ -e loopdir ]
then
	sudo umount loopdir || true
	rmdir loopdir
else
	mkdir loopdir
fi
rm -rf cd
mkdir cd
sudo mount -o loop debian-9.0.0-amd64-mini.iso loopdir
rsync -q -a -H --exclude=TRANS.TBL loopdir/ cd
sudo umount loopdir
rmdir loopdir
chmod +w --recursive cd
gunzip cd/initrd.gz
PASS=$(pwgen 20 1)
echo "Password: $PASS"
sed "s|{{HASH}}|$(echo ${PASS} | mkpasswd -s -m sha-512)|" preseed.cfg.in >preseed.cfg
echo "preseed.cfg" | cpio -o -H newc -A -F cd/initrd
gzip cd/initrd
(cd cd && md5sum $(find -follow -type f) >md5sum.txt)
genisoimage -quiet -o preseeded.iso -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux.bin -c isolinux.cat ./cd