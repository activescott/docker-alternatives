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

  IMAGE_DEF     The image definition yml file to start

END_DOC

}

[ "$#" -eq 1 ] || die "Expected one argument to be the image def"

IMAGE_DEF=$1
PREFIX=$(basename -s .yml $IMAGE_DEF)
# If you want to use hyperkit runtime, change this to BACKEND=hyperkit. Hyperkit is a PIA though. It freezes and requires vpnkit for any sane networking and that's another pain.
BACKEND=qemu

# options could be things like networking, etc. They depend a bit on the VM Runtime/backend. See https://github.com/linuxkit/linuxkit/blob/master/docs/platform-qemu.md, https://github.com/linuxkit/linuxkit/blob/master/docs/platform-hyperkit.md, etc.
OPTIONS=

linuxkit run $BACKEND $OPTIONS $PREFIX
