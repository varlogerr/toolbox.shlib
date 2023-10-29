#!/usr/bin/env bash

# shellcheck disable=SC2120

# https://stackoverflow.com/a/2705678
escape_sed_expr() { cat -- "${@}" | sed 's/[]\/$*.^[]/\\&/'; }
escape_sed_repl() { cat -- "${@}" | sed 's/[\/&]/\\&/'; }
# https://unix.stackexchange.com/a/552358
escape_printf() { cat -- "${@}" | sed -e 's/[\\%]/&&/g'; }

escape_quote_double_meta_comment() { echo "
  USAGE:
 ,  {{ CMD }} [WRAP] FILE...
 ,  {{ CMD }} [WRAP] <<< TEXT
 ,
  DEMO:
 ,  # Escape and wrap with double quotes
 ,  {{ CMD }} true <<< 'Say \"Hi\"'  # STDOUT: $(escape_quote_double true <<< 'Say "Hi"')
"; }
escape_quote_double() {
  declare wrap="${1}"; shift

  declare -a wrap_filter
  [[ "${wrap,,}" =~ ^(true|1|yes|y)$ ]] && {
    wrap_filter=(-e '1 s/^/"/' -e '$ s/$/"/')
  }

  cat -- "${@}" | sed -e 's/"/\\"/g' "${wrap_filter[@]}"
}

escape_quote_single_meta_comment() { echo "
  USAGE:
 ,  {{ CMD }} [WRAP] FILE...
 ,  {{ CMD }} [WRAP] <<< TEXT
 ,
  DEMO:
 ,  # Escape and wrap with single quotes
 ,  {{ CMD }} true <<< \"I'm Elvis\"  # STDOUT: $(escape_quote_single true <<< "I'm Elvis")
"; }
escape_quote_single() {
  declare wrap="${1}"; shift

  declare -a wrap_filter
  [[ "${wrap,,}" =~ ^(true|1|yes|y)$ ]] && {
    wrap_filter=(-e "1 s/^/'/" -e "$ s/$/'/")
  }

  cat -- "${@}" | sed -e "s/'/'\\\\''/g" "${wrap_filter[@]}"
}

# shellcheck disable=SC2034
text_to_prefixed_meta_deps=( escape_sed_expr )
text_to_prefixed_meta_comment() { echo "
  USAGE:
 ,  {{ CMD }} PREFIX FILE...
 ,  {{ CMD }} PREFIX <<< TEXT
"; }
text_to_prefixed() {
  declare prefix="${1}"; shift
  declare escaped; escaped="$(escape_sed_expr <<< "${prefix}")"
  cat -- "${@}" | sed 's/^/'"${escaped}"'/'
}

# shellcheck disable=SC2034
{
  log_sth_meta_deps=( text_to_prefixed )
  log_info_meta_deps=( log_sth )
  log_warn_meta_deps=( log_sth )
  log_fuck_meta_deps=( log_sth )
}
log_sth() {
  declare what="${1}"; shift
  cat -- "${@}" | text_to_prefixed "$(basename -- "${0}"): [${what^^}] " >&2
}
log_info() { log_sth INFO "${@}"; }
log_warn() { log_sth WARN "${@}"; }
log_fuck() { log_sth FUCK "${@}"; }

################
#### ACTION ####
################

# {{ END_LIB /}}
(return 0 &>/dev/null) && return

declare TARGET="${1}"

_cache() {
  declare -Ag __CACHE

  declare key="${1}"; shift

  [[ $# -gt 0 ]] && {
    __CACHE["${key}"]="${1}"
    "${FUNCNAME[0]}" "${key}"
    return
  }

  [[ -n "${__CACHE[$key]+x}" ]] || return 1

  printf -- '%s' "${__CACHE[${key}]}${__CACHE[${key}]:+$'\n'}"
  return 0
}

lib_body() {
  _cache "${FUNCNAME[0]}" && return

  declare self_body; self_body="$(cat -- "${0}")"
  declare self_len; self_len="$(wc -l <<< "${self_body}")"
  _cache "${FUNCNAME[0]}" "$(
    grep -m1 -B "${self_len}" '^\s*#\s*{{\s*END_LIB\s*/}}\s*' <<< "${self_body}" \
    | grep -m1 -A "${self_len}" -v '^\s*\(#.*\)\?$' \
    | tac | grep -m1 -A "${self_len}" -v '^\s*\(#.*\)\?$' | tac
  )"
}

lib_fnames() {
  _cache "${FUNCNAME[0]}" && return

  declare lib_body; lib_body="$(lib_body)"
  _cache "${FUNCNAME[0]}" "$(
    # * unset all functions
    # * import the lib functions
    # * print imported function names without meta-functions
    # * skip out readonly functions

    while read -r f; do
      [[ -n "${f}" ]] && unset -f "${f}" &>/dev/null
    done <<< "$(declare -F | rev | cut -d' ' -f1 | rev)"

    # shellcheck disable=SC1090
    . <(cat <<< "${lib_body}")

    declare -F | grep ' -[^r]\+ ' | rev | cut -d' ' -f1 | rev | grep -v '_meta_comment$'
  )"
}

# Get function dependencies (including the dependent function)
# USAGE:
#   lib_func_deps FNAME
lib_func_deps() (
  declare deps="${1}"

  declare ix=1
  declare fname new_deps
  while fname="$(sed -n "${ix}p" <<< "${deps}" | grep '.')"; do
    (( ix++ ))

    grep -Fxf <(lib_fnames) <<< "${fname}" || {
      # The function is not in the lib
      log_warn <<< "Unknown function: '${fname}'"
      continue
    }

    declare -p "${fname}_meta_deps" 2>/dev/null | grep -q '^declare -a' || continue
    new_deps="$(
      eval -- "printf -- '%s\\n' \"\${${fname}_meta_deps[@]}\"" \
      | grep -vFxf <(cat <<< "${deps}") | grep '.')" || continue

    deps+=$'\n'"${new_deps}"
  done
)

# First and last lines of snippet block in target file
target_block_lines() (
  declare target="${1}"

  _cache "${FUNCNAME[0]}" && return

  declare ptn_start='\s*#\s*{{\s*SHLIB_SNIPPET\s*}}\s*'
  declare ptn_end='[0-9]\+-\s*#\s*{{\/\s*SHLIB_SNIPPET\s*}}\s*'

  _cache "${FUNCNAME[0]}" "$(
    grep -n -x -m1 -A9999 "${ptn_start}" -- "${target}" 2>/dev/null \
    | grep -x -m1 -B9999 "${ptn_end}" | sed -n '1p;$p' | grep -o '^[0-9]\+'

    declare -i rc=$?

    [[ ${PIPESTATUS[0]} -lt 2 ]] || {
      log_fuck <<< "Can't read file: '${target}'"
      exit 2
    }

    [[ ${rc} -lt 1 ]] || {
      log_fuck <<< "Can't detect SHLIB_SNIPPET block in file: '${target}'"
    }

    exit ${rc}
  )"
)

declare lines_txt; lines_txt="$(target_block_lines "${TARGET}")"
rc=$?
[[ $rc -lt 2 ]] || exit ${rc}

if [[ ${rc} -gt 0 ]]; then
  :
  # TODO: block not found, create it
fi

declare -a TARGET_LINES; mapfile -t TARGET_LINES <<< "${lines_txt}"

declare REQUESTED; REQUESTED="$(
  sed -n "${TARGET_LINES[0]},${TARGET_LINES[1]}p" "${TARGET}" \
  | sed '1d' | grep -m1 -B9999 -v '^\s*#\s*@' \
  | sed -e '$d' -e 's/^\s*#\s*@\(.\+\)/\1/' | grep ''
)" || {
  log_warn <<< "No requested functions in file: '${TARGET}'"
  exit 0
}

declare REQUESTED_DEPS
REQUESTED_DEPS="$(lib_func_deps "${REQUESTED}" | grep '')" || exit 1

declare UPDATE; UPDATE="$(
  declare -i ctr=0
  while read -r f; do
#    [[ ${ctr} -gt 0 ]] && echo

    comment_fnc="${f}_meta_comment"
    declare -F "${comment_fnc}" &>/dev/null && {
      repl="$(escape_sed_repl <<< "${f}")"

      "${comment_fnc}" | sed -e 's/^\s*//' -e '/^$/d' -e 's/^,//' \
        -e 's/{{\s*CMD\s*}}/'"${repl}"'/' | text_to_prefixed '# '
    }

    echo '# shellcheck disable=SC2120'
    declare -f "${f}"

    (( ctr++ ))
  done <<< "${REQUESTED_DEPS}"
)"

UPDATE="$(text_to_prefixed '# @' <<< "${REQUESTED}")${REQUESTED:+$'\n\n'}${UPDATE}"
TARGET_TEXT="$(cat -- "${TARGET}")"

{
  head -n "${TARGET_LINES[0]}" <<< "${TARGET_TEXT}"
  printf -- '%s' "${UPDATE}${UPDATE:+$'\n'}"
  tail -n +"${TARGET_LINES[1]}" <<< "${TARGET_TEXT}"
} | tee -- "${TARGET}" >/dev/null
