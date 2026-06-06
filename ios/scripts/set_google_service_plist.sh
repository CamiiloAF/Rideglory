#!/bin/sh
# Copia el GoogleService-Info.plist del flavor activo al bundle de Runner.
# Se invoca como Run Script build phase ANTES de "Copy Bundle Resources".
#
# El flavor se deduce del nombre de la build configuration de Xcode:
#   *-dev / Debug-dev / Release-dev  -> dev
#   cualquier otra                   -> prod
#
# Requiere que existan:
#   ios/config/dev/GoogleService-Info.plist
#   ios/config/prod/GoogleService-Info.plist

set -e

case "${CONFIGURATION}" in
  *dev* | *Dev* | *DEV*)
    FLAVOR="dev"
    ;;
  *)
    FLAVOR="prod"
    ;;
esac

SRC="${PROJECT_DIR}/config/${FLAVOR}/GoogleService-Info.plist"
DST="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ ! -f "${SRC}" ]; then
  echo "error: no existe ${SRC}" >&2
  exit 1
fi

echo "Usando GoogleService-Info.plist del flavor '${FLAVOR}' (CONFIGURATION=${CONFIGURATION})"
cp "${SRC}" "${DST}"
