#!/bin/bash

### 2nd Build ###

cd openwrt

### extra stuff for luci
git clone https://github.com/gSpotx2f/luci-app-temp-status.git feeds/luci/applications/luci-app-temp-status
git clone https://github.com/gSpotx2f/luci-app-cpu-status.git feeds/luci/applications/luci-app-cpu-status

#Update base OpenWrt Feeds
./scripts/feeds update -a
./scripts/feeds install -a

### My Build Config
\cp -r ../files/prek_build.config .config

### uncomment the line below to make your own config
#make menuconfig
make -j$(nproc) V=s

exit 0
