#!/usr/bin/env sh
THISDIR=$(cd $(dirname "$0"); pwd) #this script's directory
THISSCRIPT=$(basename $0)
THISSCRIPT_BASE=$(basename -s .sh $0)

die () {
    echo >&2 "$@"
    help
    exit 1
}

help () {
  echo 
  cat << END_DOC
USAGE: $THISSCRIPT IMAGE_DEF [options]

  IMAGE_DEF     The image definition file to $THISSCRIPT_BASE

options: Depends on the underlying podman comand. See https://docs.podman.io/en/latest/Commands.html

END_DOC

}

[ "$#" -ge 1 ] || die "Expected at least one argument to be the image def (got $#)"

IMAGE_DEF=$1
PREFIX=$(basename -s .containerfile $IMAGE_DEF)
# shift to allow remaining arguments to be handled below
shift
# clear options:
OPTIONS=
# all other options are forwarded to the linuxkit command
OPTIONS="$@"

##########
echo "stoping container '$PREFIX' with options '$OPTIONS'..."
podman stop $PREFIX
echo "stoping container complete."
