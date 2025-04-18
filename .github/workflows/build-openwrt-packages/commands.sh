#!/usr/bin/env bash
set -eo pipefail

# build-openwrt-packages-commands.sh
# Wird im Container ausgeführt. ENV-Variablen OPENWRT_VERSION und GIT_TAG sind gesetzt.

# 1) OpenWRT sources klonen
git clone --branch v"$OPENWRT_VERSION" https://git.openwrt.org/openwrt/openwrt.git
# 2) Paket-Repo klonen
git clone --branch "$GIT_TAG" https://github.com/Zerogiven-OpenWRT-Packages/Quectel-RM520N-Thermal.git openwrt/package/quectel-rm520n-thermal
cd openwrt

# 3) Feeds aktualisieren und installieren
./scripts/feeds update -a
./scripts/feeds install -a

# 4) Standard-Konfiguration herunterladen
wget "https://mirror-03.infra.openwrt.org/releases/$OPENWRT_VERSION/targets/mediatek/filogic/config.buildinfo" -O .config
make defconfig

# 5) Quectel-Paket aktivieren
sed -i 's|^# CONFIG_PACKAGE_quectel-rm520n-thermal is not set$|CONFIG_PACKAGE_quectel-rm520n-thermal=m|' .config

# 6) Toolchain installieren und Kernel/Packages kompilieren
make -j"$(nproc)" toolchain/install
make -j"$(nproc)" target/linux/compile
make -j"$(nproc)" package/kernel/linux/compile
make -j"$(nproc)" V=sc package/quectel-rm520n-thermal/compile

# 7) Artefakte finden und in Version-Ordner kopieren
KMOD_FILE=$(ls bin/targets/mediatek/filogic/packages/kmod-quectel-rm520n-thermal_*_"$GIT_TAG"_all.ipk)
DAEMON_FILE=$(ls bin/packages/aarch64_cortex-a53/base/quectel-rm520n-thermal_"$GIT_TAG"_all.ipk)
SHORT_VER="$(echo "$OPENWRT_VERSION" | awk -F. '{print $1 "." $2}')"
mkdir -p /openwrt-bin/"$SHORT_VER"
cp "$KMOD_FILE" /openwrt-bin/"$SHORT_VER"/
cp "$DAEMON_FILE" /openwrt-bin/"$SHORT_VER"/
