#! /bin/bash

######################
# Helper Methods
######################
set -e -o pipefail


BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ANDROID_VERSION="9.0"

indocker () {
  if [ -f /.dockerenv ]; then
    cd proj
    "$@"
  else
    docker run -it --rm \
      -v $BASEDIR:/root/proj \
      -v $HOME/.gradle:/root/.gradle \
      budtmo/docker-android-x86-${ANDROID_VERSION} \
      proj/$(basename ${BASH_SOURCE[0]}) "$@"
  fi
}

start_emulator() {
  docker run --privileged -d -p 6080:6080 -p 5554:5554 -p 5555:5555 \
    -e DEVICE="Samsung Galaxy S6" \
    --name android-container \
    budtmo/docker-android-x86-${ANDROID_VERSION}
}

build_demo() {
  echo "Assemble DEMO APK"
  cd PrebidMobile
  #./gradlew -i --no-daemon API1.0:assembleDebug API1.0Demo:assembleDebug
  ./gradlew -i --no-daemon DemoApp:assembleDebug
}

build_prebid() {
  ./buildprebid.sh
}

_adb_connect() {
  adb connect 172.17.0.2:5555
}

adb_shell() {
  _adb_connect
  adb shell
}

adb_logcat() {
  _adb_connect
  adb shell setprop log.tag.PrebidMobile DEBUG
  adb shell setprop log.tag.Prebid DEBUG
  adb shell setprop log.tag.MoPub DEBUG
  adb shell logcat *:S MoPub:* PrebidMobile:* Prebid:* Ads:*
}

install_demo() {
  _adb_connect
  adb uninstall  org.prebid.mobile.api1demo || true
  adb install -r PrebidMobile/API1.0Demo/build/outputs/apk/sourceCode/debug/API1.0Demo-sourceCode-debug.apk
  adb shell am start -n org.prebid.mobile.api1demo/org.prebid.mobile.app.MainActivity
}

run() {
  echo "running"
  "$@"
}

#cmd=$1
#shift

indocker "$@"
