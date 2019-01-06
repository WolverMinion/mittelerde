HOS_VERSION=1.9.0
HOS_URL=https://github.com/hypriot/image-builder-rpi/releases/download
curl -LO ${HOS_URL}/v${HOS_VERSION}/hypriotos-rpi-v${HOS_VERSION}.img.zip
unzip hypriotos-rpi-v${HOS_VERSION}.img.zip
rm -rf hypriotos-rpi-v${HOS_VERSION}.img.zip