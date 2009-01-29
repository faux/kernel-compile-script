#!/bin/bash
## Packages needed to run this script
COMMON_PACKAGES="build-essential bin86 kernel-package wget curl"
CONSOLE_PACKAGES="libncurses5 libncurses5-dev"
X_PACKAGES="libqt3-headers libqt3-mt-dev"

## Print usage options

USAGE="Usage: $0 [ --console | --xconsole ] [--download] [--extract] [--newconfig] [--useconfig=PATH]"

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
    --download)
      DOWNLOAD_KERNEL="TRUE"
      ;;
    --extract)
      EXTRACT_KERNEL="TRUE"
      ;;
    --newconfig)
      NEW_CONFIG="TRUE"
      ;;
    --useconfig=*)
      USE_CONFIG=$(echo "$1" | sed 's/^--useconfig=//')
      ;;
    *)
      echo "$USAGE"
      exit 1
      ;;
  esac
shift
done

apt-get install $COMMON_PACKAGES $ADDITIONAL_PACKAGES

cd /usr/src

DOWNLOAD_PATH=`curl -s kernel.org | grep "/pub/linux/kernel/" | grep ">F<" | cut -d'"' -f2 | head -n 1`
KERNEL_FILENAME=`echo $DOWNLOAD_PATH | tr "/" "\n" | tail -n 1`
KERNEL_FIELDCNT=`echo $KERNEL_FILENAME | tr "." "\n" | head -n -2 | wc -l`
KERNEL_DIR=`echo $KERNEL_FILENAME | tr "." "\n" | head -n -2 |  tr "\n" "." | cut -d"." --field=-$KERNEL_FIELDCNT`

echo "==================="
if [ ! -f "$KERNEL_FILENAME" -o -n "$DOWNLOAD_KERNEL" ]; then
  if [ -f "$KERNEL_FILENAME" ]; then
    rm "$KERNEL_FILENAME"
  fi
  wget -c http://kernel.org$DOWNLOAD_PATH
else
  echo "$KERNEL_FILENAME already exists"
fi
echo "==================="
if [ ! -d "$KERNEL_DIR" -o -n "$EXTRACT_KERNEL" ]; then
  if [ -d "$KERNEL_DIR" ]; then
    rm -rf "$KERNEL_DIR"
  fi
  tar -xvjf $KERNEL_FILENAME
else
  echo "$KERNEL_DIR already exists"
fi


echo
echo $KERNEL_DIR
cd $KERNEL_DIR

if [ -z "$NEW_CONFIG" -a -z "$USE_CONFIG" ]; then
  cp /boot/config-$(uname -r) .config
elif [ -n "$USE_CONFIG" ]; then
  cp "$USE_CONFIG" .config
fi
exit 1
yes "" | make oldconfig

make xconfig
#make menuconfig

make-kpkg clean

CONCURRENCY_LEVEL=3 time make-kpkg --initrd --revision=64 kernel_image kernel_headers modules_image

