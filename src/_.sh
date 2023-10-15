# TODO: remove when shlib in master

declare SELF SELF_DIR
SELF="${BASH_SOURCE[0]}"; SELF_DIR="$(dirname -- "${SELF}")"

declare f; for f in "${SELF_DIR}/lib"/*.sh; do
  # shellcheck disable=SC1090
  . "${f}"
done
