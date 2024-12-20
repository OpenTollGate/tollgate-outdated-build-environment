## Setup using https://firmware-selector.openwrt.org/

This is based on blog post found at https://aparcar.org/running-openwrt-on-hetzner/

Visit https://firmware-selector.openwrt.org/

Select Generic x86/64

Click Customize installed packages and/or first boot script

Remember to make changes to files/firstboot/firstboot_02_ssh to change to your own ssh keys. Passwords will be disabled for root login

cat files/firstboot/firstboot_all_01_password_tollgate \
    files/firstboot/firstboot_01_disallow_passwords_for_ssh \
    files/firstboot/firstboot_02_ssh                            > /tmp/firstboot.vps

copy and paste result into "Script to run on first boot (uci-defaults)"

request build

Download COMBINED-EFI(EXT4) or COMBINED-EFI(SQUASHFS)

scp openwrt-23.05.5-*-x86-64-generic-*-combined-efi.img.gz root@myvpn:/tmp

ssh root@myvpn "cd /tmp && gzip -c -d < $(ls openwrt-23.05.5-*-x86-64-generic-*-combined-efi.img.gz) | dd of=/dev/sda && reboot"

ssh root@myvpn
