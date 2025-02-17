# Setup build environment from scratch

Clone this repo and make sure your on the branch that needs
testing. If you want to try a branch that "just works", you should
probably go for `main`.
```
git clone https://github.com/OpenTollGate/TollGateNostrToolKit.git
cd TollGateNostrToolKit/
```

Run the `build_coordinator` as a non root user in the sudoers
list. You will be prompted for the sudo password to install
dependencies. Consider using `screen` if your on a VPS, because the
initial build will take long and it would be a pity if it gets
interrupted.
```
./build_coordinator.sh 
```


`./build_coordinator.sh` builds TollGate for all routers that have a
make config file under `./routers/*_config` using
`./install_script.sh` to place configurations from `./files/` into the
filesystem of the `sysupgrade.bin` file.

You can find your newly created sysupgrade file in
`./binaries/openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade_[commit_hash].bin`.

It can take over an hour to build its your first time building
TollGate, but `build_coordinator.sh` only takes minutes if you run it
again after having changed something in `files` without changing any
of source code that affects openwrt's binaries and without having
changed the configuration files in `routers`. You can force
`build_coordinator.sh` to rebuild from scratch by deleting
`~/openwrt`.

You can modify the contents of `./files` and/or `install_script.sh` to
change the initial content of the filesystem in `sysupgrade.bin`.

The following make command was used to collect logs, so you can
inspect `~/openwrt/make_logs.md` in case of build failure.
```
make -j$(nproc) V=sc > make_logs.md 2>&1
```

## Flashing the router

You can use `ifconfig` to find the IP address of your openwrt router when its connected to your computer.

Use the following command to copy your sysupgrade file to the router:
```
scp openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade_[commit_hash].bin root@[router_ip]:/tmp/.
```

Now log in to the router, navigate to `/tmp` and use the following command to flash it with the sysupgrade file:
```
sysupgrade -n openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade_[commit_hash].bin
```

The router will take a few minutes to install the sysupgrade file and
it should show up with a new IP address that you can find with
`ifconfig`. Now log in with ssh again and follow the instructions to
set your password and LNURL.

## Some basic documentation

- [Setup from Scratch](docs/setup_from_scratch.md): Detailed instructions for setting up the build environment in a new VPS.
- [Updating Feeds Configuration in OpenWrt](docs/updating_feeds_conf_in_openwrt.md): Guide on how to update the feeds configuration in OpenWrt.
- [Uploading Binaries to GitHub Releases](docs/upload_binaries_to_github.md): Instructions for uploading binaries to GitHub releases without adding them to the git repository.
- [Setting DNS Server](docs/setting_dns_server.md): Instructions for setting DNS server.
- [Find error in logs](docs/find_error_in_logs.md): Commands for parsing through `build_logs.md` to find relevant lines.
- [Synchronize nodogsplash.conf with UCI](docs/nodogsplash_configuration.md): nodogsplash gets its commands from `/etc/nodogsplash/nodogsplash.conf`, but the UCI commands modify `/etc/config/nodogsplash`. Logic is required to transfer the UCI settings to `nodogsplash.conf` on startup.
- [Squashing a diverged branch](docs/squash_commits_since_main.md): squash all commits on the current branch since the point where it diverged from main. This makes the branch easier to rebase onto main.

## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.