HOSTNAME=$1
HOS_VERSION=1.9.0
USER_DATA="user-data"

echo "Install '${HOS_VERSION}' with '${USER_DATA}' and '${HOSTNAME}'"

flash -n "${HOSTNAME}" -u "${USER_DATA}" hypriotos-rpi-v${HOS_VERSION}.img