#!/bin/sh

# Location for store source "debian-XX.X.X-xxx-netinst.iso", "menu.cfg", "preseed.cfg", etc..
SRC_DIR="$(pwd)"

ISO_SVR="cdimage.debian.org"
ISO_VER="12.11.0"
ISO_FILE="debian-${ISO_VER}-amd64-netinst.iso"
ISO_URL="https://${ISO_SVR}/debian-cd/${ISO_VER}/amd64/iso-cd/${ISO_FILE}"

ISO_AUTOINSTALL="/tmp/auto-install.iso"

WORKDIR="$(mktemp -d /tmp/rebuild-iso-XXXXX)"
cd ${WORKDIR} || { echo "Hmm, can't chdir to workdir '${WORKDIR}'"; exit; }

cd ${SRC_DIR} || { echo "No SRC_DIR '${SRC_DIR}'?"; exit; }
[ ! -f ${ISO_FILE} ] && { echo "NO ${ISO_FILE} file, will try download"; wget ${ISO_URL}; }
[ ! -f ${ISO_FILE} ] && { echo "Hmm, can't get iso file '${ISO_FILE}'"; exit; }

if [ ! -f "/bin/xorriso" -o ! -d "/usr/lib/ISOLINUX" ]; then
	apt-get update && \
	apt-get -y install xorriso isolinux
fi

mkdir -p ${WORKDIR}/temp
[ ! -d "${WORKDIR}/temp" ] && { echo "No '${WORKDIR}/temp' directory"; exit; }

echo "=== xorriso extract iso file ==="
xorriso	\
    -osirrox on \
    -indev ${SRC_DIR}/${ISO_FILE} \
    -extract / ${WORKDIR}

chmod -R +w ${WORKDIR}

echo "=> copy preseed files"
cp -v ${SRC_DIR}/preseed.cfg ${WORKDIR}/temp/

echo "=> copy menu.cfg file"
cp -v ${SRC_DIR}/menu.cfg ${WORKDIR}/isolinux

echo "=> copy firstrun.sh script"
cp -v ${SRC_DIR}/firstrun.sh ${WORKDIR}/temp/

echo "=> copy rc.local script"
cp -v ${SRC_DIR}/rc.local ${WORKDIR}/temp/

echo "=> copy get-target-disk.sh script"
cp -v ${SRC_DIR}/get-target-disk.sh ${WORKDIR}/temp/

echo "=== xorriso rebuild iso file ==="
xorriso	\
    -as mkisofs \
    -o ${ISO_AUTOINSTALL} \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    ${WORKDIR}

rm -rvf ${WORKDIR}
