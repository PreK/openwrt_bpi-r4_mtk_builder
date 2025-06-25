#!/bin/bash

### delete old folders (if they exist) for a clean build
rm -rf openwrt
rm -rf mtk-openwrt-feeds

### clone required repos
git clone --branch main https://git.openwrt.org/openwrt/openwrt.git openwrt || true
git clone  https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
#cd mtk-openwrt-feeds; git checkout f737b2f5f33d611f9e96f91ffccd0531700b6282; cd -;	#Add Airoha AN8831X 10G PHY driver package
#echo "f737b2f" > mtk-openwrt-feeds/autobuild/unified/feed_revision

### wireless-regdb modification - this remove all regdb wireless countries restrictions
rm -rf openwrt/package/firmware/wireless-regdb/patches/*.*
rm -rf mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches/*.*
\cp -r files/500-tx_power.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches
\cp -r files/regdb.Makefile openwrt/package/firmware/wireless-regdb/Makefile

### radio noise reading fix
wget https://raw.githubusercontent.com/woziwrt/bpi-r4-openwrt-builder/refs/heads/main/my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch \
 -O openwrt/package/network/utils/iwinfo/patches/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch

### original txpower fix
#wget https://raw.githubusercontent.com/woziwrt/bpi-r4-openwrt-builder/refs/heads/main/my_files/99999_tx_power_check.patch \
 #-O mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/99999_tx_power_check.patch

### fix "use-tx_power-from-default-fw-if-EEPROM-contains-0"
wget https://github.com/openwrt/mt76/commit/aaf90b24fde77a38ee9f0a60d7097ded6a94ad1f.patch \
 -O mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/9997-use-tx_power-from-default-fw-if-EEPROM-contains-0s.patch

### required & thermal zone 
wget https://raw.githubusercontent.com/woziwrt/bpi-r4-openwrt-builder/refs/heads/main/my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch \
 -O mtk-openwrt-feeds/24.10/patches-base/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch

## adjust some config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt  
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

exit 0
