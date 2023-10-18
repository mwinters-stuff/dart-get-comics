#!/bin/sh
# set -eux

BASEURL="https://storage.googleapis.com/dart-archive/channels"
DART_VER=$VERSION
export DEBIAN_FRONTEND="noninteractive"
apt update
apt install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    xz-utils \
    zip \
    file

case "$(dpkg --print-architecture)" in
amd64)
    DART_SHA256=cccd5300faa5a9abce12a5f77586e26350028cea82bb4ff8eeb55641b58a2e1d
    SDK_ARCH="x64"
    ;;
armhf)
    DART_SHA256=3a15d42cb1677ac5e50a23045cafe3bf5db2855a5287a3e9019b849fe8477897
    SDK_ARCH="arm"
    ;;
arm64)
    DART_SHA256=2c8eeaf0d3da60c4e14beec45ce3b39aca754f71b9fa3fb0c635ee28d6f44708
    SDK_ARCH="arm64"
    ;;
esac

SDK="dartsdk-linux-${SDK_ARCH}-release.zip"
URL="$BASEURL/stable/release/${DART_VER}/sdk/$SDK"
curl -fLO "$URL"
echo "$DART_SHA256 *$SDK" | sha256sum --check --status --strict -
unzip "$SDK"
mv dart-sdk "$DART_ROOT"
rm "$SDK"
chmod 755 "$DART_ROOT"
chmod 755 "$DART_ROOT/bin"
