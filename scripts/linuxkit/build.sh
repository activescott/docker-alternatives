#!/usr/bin/env sh
THISDIR=$(cd $(dirname "$0"); pwd) #this script's directory
THISSCRIPT=$(basename $0)

die () {
    echo >&2 "$@"
    help
    exit 1
}

help () {
  echo 
  cat << END_DOC
USAGE: $THISSCRIPT IMAGE_DEF

  IMAGE_DEF     The image definition yml file to build

END_DOC

}

[ "$#" -eq 1 ] || die "Expected one argument to be the image def"

IMAGE_DEF=$1
PREFIX=$(basename -s .yml $IMAGE_DEF)

linuxkit build -format "kernel+initrd" "$IMAGE_DEF"
