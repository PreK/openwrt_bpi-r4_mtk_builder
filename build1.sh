#!/bin/bash
set -euo pipefail

### Clean previous build folders
rm -rf openwrt
rm -rf mtk-openwrt-feeds

### Clone OpenWrt (main branch)
git clone --branch main https://git.openwrt.org/openwrt/openwrt.git openwrt

### Clone MediaTek MTK feeds (master branch)
git clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds mtk-openwrt-feeds

### Apply MTK base patches (optional but recommended)
cd openwrt
mkdir -p feeds/mtk_openwrt_feed/patches-base
cp -a ../mtk-openwrt-feeds/patches-base/*.patch feeds/mtk_openwrt_feed/patches-base/

# Skip known incompatible patch (already integrated or obsolete)
for patch in feeds/mtk_openwrt_feed/patches-base/*.patch; do
  case "$patch" in
    *0100-filogic-01-add-support-for-MediaTek-RFBs.patch) echo "Skipping incompatible patch: $patch"; continue ;;
  esac
  echo "Applying patch: $patch"
  patch -p1 < "$patch" || echo "Warning: Failed to apply $patch"
done


### Update and install OpenWrt feeds
./scripts/feeds update -a
./scripts/feeds install -a

### Optional: Remove wireless regulatory restrictions
rm -rf package/firmware/wireless-regdb/patches/*.*
cp -v ../files/500-tx_power.patch package/firmware/wireless-regdb/patches/
cp -v ../files/regdb.Makefile package/firmware/wireless-regdb/Makefile

### Fix for iwinfo noise reading
wget https://raw.githubusercontent.com/woziwrt/bpi-r4-openwrt-builder/main/my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch \
  -O package/network/utils/iwinfo/patches/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch

### TX Power EEPROM zero fix (for mt76)
wget https://github.com/openwrt/mt76/commit/aaf90b24fde77a38ee9f0a60d7097ded6a94ad1f.patch \
  -O package/kernel/mt76/patches/9997-use-tx_power-if-eeprom-0.patch

### Thermal zone support for MT7988
wget https://raw.githubusercontent.com/woziwrt/bpi-r4-openwrt-builder/main/my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch \
  -O target/linux/mediatek/patches-6.6/1007-wozi-add-thermal-zone.patch

### Optional: Remove perf package if unwanted (depends on config)

## adjust some config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config
### Start build process (adjust target if needed)
make menuconfig  # Select MT7988 target and options manually
make -j$(nproc) V=s

exit 0
