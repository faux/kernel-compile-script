#!/bin/bash
## Packages needed to run this script
COMMON_PACKAGES="build-essential bin86 kernel-package wget curl"
CONSOLE_PACKAGES="libncurses5 libncurses5-dev"
X_PACKAGES="libqt3-headers libqt3-mt-dev"

## Print usage options

USAGE="Usage: $0 [ --console | --xconsole ]"

if [ $# -eq 0 ]; then
  echo "$USAGE"
  exit 1
fi

## Parse options

while (( "$#" )); do
  case "$1" in
    --console)
      ADDITIONAL_PACKAGES="$CONSOLE_PACKAGES"
      CONFIG_OPTION="CONSOLE"
      ;;
    --xconsole)
      ADDITIONAL_PACKAGES="$X_PACKAGES"
      CONFIG_OPTION="X"
      ;;
    *)
      echo "$USAGE"
      exit 1
      ;;
  esac
shift
done



echo "$ADDITIONAL_PACKAGES"
echo "$CONFIG_OPTION"
exit

apt-get install $COMMON_PACKAGES $ADDITIONAL_PACKAGES

cd /usr/src

DOWNLOAD_PATH=`curl kernel.org | grep "/pub/linux/kernel/" | grep ">F<" | cut -d'"' -f2 | head -n 1`
KERNEL_FILENAME=`echo $DOWNLOAD_PATH | tr "/" "\n" | tail -n 1`
KERNEL_FIELDCNT=`echo $KERNEL_FILENAME | tr "." "\n" | head -n -2 | wc -l`
KERNEL_DIR=`echo $KERNEL_FILENAME | tr "." "\n" | head -n -2 |  tr "\n" "." | cut -d"." --field=-$KERNEL_FIELDCNT`

wget -c http://kernel.org$DOWNLOAD_PATH
tar -xvjf $KERNEL_FILENAME
echo
echo $KERNEL_DIR
cd $KERNEL_DIR

cp /boot/config-$(uname -r) .config

yes "" | make oldconfig

make xconfig
#make menuconfig

make-kpkg clean

CONCURRENCY_LEVEL=3 time make-kpkg --initrd --revision=64 kernel_image kernel_headers modules_image

