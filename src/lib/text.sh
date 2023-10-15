# https://unix.stackexchange.com/a/31955
# shellcheck disable=SC2120
text_ensure_nl() {
  { # Args
    # TODO: Autogen

    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare -a ARG_FILE

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      ## TODO: print help
      # SOME IMPLEMENTATION
      # return 0

      log_fuck 'Not implemented yet: `--help`'.
      return 2
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    declare SHLIB_LOG_CALLER="${SHLIB_LOG_CALLER-${FUNCNAME[0]}}"
    declare file; for file in "${ARG_FILE[@]--}"; do
      cati "${file}" | sed '$a\'
    done
  } # Body
}

text_fmt() {
  { # Args
    # TODO: Autogen

    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare -a ARG_FILE

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      ## TODO: print help
      # SOME IMPLEMENTATION
      # return 0

      log_fuck 'Not implemented yet: `--help`'.
      return 2
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    declare -i t_lines offset
    declare -a rm_blanks
    declare SHLIB_LOG_CALLER="${SHLIB_LOG_CALLER-${FUNCNAME[0]}}"
    declare text
    declare file; for file in "${ARG_FILE[@]--}"; do
      text="$(cati "${file}")"
      t_lines="$(wc -l <<< "${text}")"
      rm_blanks=(grep -m1 -A "${t_lines}" -vx '\s*')
      # Remove blank lines from the beginning end and
      text="$(set -o pipefail
        "${rm_blanks[@]}" <<< "${text}" \
        | tac  | "${rm_blanks[@]}" | tac
      )" || continue
      # Calculate first line offset
      offset="$(sed -e '1!d' -e 's/^\(\s*\).*/\1/' <<< "${text}" | wc -m)"
      # Trim offset
      sed -e 's/^\s\{0,'$((offset - 1))'\}//' \
        -e 's/\s\+$//' <<< "${text}" | text_ensure_nl
    done
  } # Body
}

text_prefix() {
  { # Args
    # TODO: Autogen

    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare OPT_COUNT OPT_PREFIX
    declare DEFAULT_PREFIX=' ' DEFAULT_COUNT=2
    declare -a ARG_FILE

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        --count=*   )
          [[ -n ${OPT_COUNT} ]] && ERRBAG+=("Single occurrence allowed: '${1%%=*}'.")
          OPT_COUNT="${1#*=}"
          grep -qx '[0-9]\+' <<< "${OPT_COUNT}" || ERRBAG+=("Invalid value: '${1}'.")
          ;;
        -c|--count  )
          [[ -n ${OPT_COUNT} ]] && ERRBAG+=("Single occurrence allowed: '${1}'.")
          if [[ -n "${2+x}" ]]; then
            OPT_COUNT="${2}"
            grep -qx '[0-9]\+' <<< "${OPT_COUNT}" || ERRBAG+=("Invalid value: '${1} ${2}'.")
          else
            ERRBAG+=("Value required: '${1}'.")
          fi
          shift
          ;;
        --prefix=*  )
          [[ -n ${OPT_PREFIX} ]] && ERRBAG+=("Single occurrence allowed: '${1%%=*}'.")
          OPT_PREFIX="${1#*=}"
          ;;
        --prefix    )
          [[ -n ${OPT_PREFIX} ]] && ERRBAG+=("Single occurrence allowed: '${1}'.")
          [[ -n "${2+x}" ]] || ERRBAG+=("Value required: '${1}'.")
          OPT_PREFIX="${2}"
          shift
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done

    [[ -n "${OPT_PREFIX}" ]] || OPT_PREFIX="${DEFAULT_PREFIX}"
    [[ -n "${OPT_COUNT}" ]] || OPT_COUNT="${DEFAULT_COUNT}"

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      ## TODO: print help
      # SOME IMPLEMENTATION
      # return 0

      log_fuck 'Not implemented yet: `--help`'.
      return 2
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    declare offset=''
    [[ ${OPT_COUNT} -gt 0 ]] && {
      declare esc_prefix; esc_prefix="$(printf -- '%s' "${OPT_PREFIX}" | escape_printf)"
      offset="$(printf -- "${esc_prefix}"'%.0s' $(seq 1 ${OPT_COUNT}))"
    }
    offset="$(escape_sed -r "${offset}")"

    declare expr='s/^/'"${offset}"'/'
    SHLIB_LOG_CALLER="${SHLIB_LOG_CALLER-${FUNCNAME[0]}}" \
      cati "${ARG_FILE[@]}" | sed -e "${expr}" -e 's/^\s\+$//'
  } # Body
}

text_tpl() {
  { # Args
    # TODO: Autogen

    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare OPT_FIRST=false     # Autogen by meta-opt `--flag`
    declare OPT_ONLY=false      # Autogen by meta-opt `--flag`
    declare OPT_SINGLE=false    # Autogen by meta-opt `--flag`
    declare OPT_BRACES          # Autogen by meta-opt `--flag`
    declare -a OPT_KV           # Autogen by meta-opt `--multi`

    declare -a ARG_FILE         # Autogen by meta-arg `--multi`

    declare DEFAULT_BRACES='{{KEY}}'

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -f|--first  )
          ${OPT_FIRST} && ERRBAG+=(
            "Single occurrence allowed: '${1}'."
          ) || OPT_FIRST=true
          ;;
        -o|--only   )
          ${OPT_ONLY} && ERRBAG+=(
            "Single occurrence allowed: '${1}'."
          ) || OPT_ONLY=true
          ;;
        -s|--single )
          ${OPT_SINGLE} && ERRBAG+=(
            "Single occurrence allowed: '${1}'."
          ) || OPT_SINGLE=true
          ;;
        --brackets=*  )
          [[ -n ${OPT_BRACES} ]] && ERRBAG+=("Single occurrence allowed: '${1%%=*}'.")
          OPT_BRACES="${1#*=}"
          grep -qx '.\+KEY.\+' <<< "${OPT_BRACES}" || ERRBAG+=("Invalid value: '${1}'.")
          ;;
        --brackets    )
          [[ -n ${OPT_BRACES} ]] && ERRBAG+=("Single occurrence allowed: '${1}'.")
          if [[ -n "${2+x}" ]]; then
            OPT_BRACES="${2}"
            grep -qx '.\+KEY.\+' <<< "${OPT_BRACES}" || ERRBAG+=("Invalid value: '${1}'.")
          else
            ERRBAG+=("Value required: '${1}'.")
          fi
          shift
          ;;
        --kv=*  )
          declare kv="${1#*=}"

          if grep -q '=' <<< "${kv}"; then
            OPT_KV+=("${kv}")
          else
            ERRBAG+=("Invalid key-value format: '${1}'.");
          fi
          ;;
        --kv    )
          if [[ -z "${2+x}" ]]; then
            ERRBAG+=("Key-value required: '${1}'.")
          elif grep -q '=' <<< "${2}"; then
            OPT_KV+=("${2}")
          elif [[ -n "${3+x}" ]]; then
            OPT_KV+=("${2}=${3}"); shift
          else
            ERRBAG+=("Invalid key-value format: '${1} ${2}'.");
          fi

          shift
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done

    OPT_BRACES="${OPT_BRACES-${DEFAULT_BRACES}}"

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      ## TODO: print help
      # SOME IMPLEMENTATION
      # return 0

      log_fuck 'Not implemented yet: `--help`'.
      return 2
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    declare BRACE_OPEN="${OPT_BRACES%KEY*}"; BRACE_OPEN="$(escape_sed -- "${BRACE_OPEN}")"
    declare BRACE_CLOSE="${OPT_BRACES#*KEY}"; BRACE_CLOSE="$(escape_sed -- "${BRACE_CLOSE}")"

    # Unique keys and values, last win
    declare -A tmp
    declare -a KEYS VALS
    declare -i ix; for ((ix=${#OPT_KV[@]}-1; ix>=0; ix--)); do
      key="${OPT_KV[$ix]%%=*}"; val="${OPT_KV[$ix]#*=}"
      [[ -n "${tmp[$key]+x}" ]] && continue

      tmp["${key}"]=''
      KEYS+=("${key}"); VALS+=("${val}")
    done

    declare -a ESC_KEYS ESC_VALS
    declare -a reduce_filter=(cat)
    [[ ${#KEYS[@]} -gt 0 ]] && {
      # Escape keys and values

      declare tmp; tmp="$(printf -- '%s\n' "${KEYS[@]}" | escape_sed)"
      mapfile -t ESC_KEYS <<< "${tmp}"
      tmp="$(printf -- '%s\n' "${VALS[@]}" | escape_sed -r)"
      mapfile -t ESC_VALS <<< "${tmp}"

      ${OPT_ONLY} && {
        # Print only affected lines filter

        declare keys_rex
        ${OPT_FIRST} && keys_rex="^\s*"
        keys_rex+="${BRACE_OPEN}"'\s*\('"$(
          printf -- '%s\|' "${ESC_KEYS[@]}" | sed -e 's/\\|$//'
        )"'\)\s*'"${BRACE_CLOSE}"

        reduce_filter=(grep "${keys_rex}")
      }
    }

    # Replacement filter
    declare -a replace_filter=(sed -e 's/^//')
    declare -A rex repl
    declare flags
    declare -i ix; for ix in "${!ESC_KEYS[@]}"; do
      rex=([prefix]='' [expr]="${BRACE_OPEN}\\s*${ESC_KEYS[$ix]}\\s*${BRACE_CLOSE}")
      repl=([prefix]='' [expr]="${ESC_VALS[$ix]}")
      flags=''

      ${OPT_SINGLE} || flags+=g
      ${OPT_FIRST} && {
        rex[prefix]='^\(\s*\)'
        repl[prefix]='\1'
      }

      [[ -n "${repl[expr]}" ]] && {
        replace_filter+=(-e "s/${rex[prefix]}${rex[expr]}/${repl[prefix]}${repl[expr]}/${flags}")
        continue
      }
    done

    SHLIB_LOG_CALLER="${SHLIB_LOG_CALLER-${FUNCNAME[0]}}" \
      cati "${ARG_FILE[@]}" | "${reduce_filter[@]}" \
      | "${replace_filter[@]}"
  } # Body
}

text_wrap() {
  { # Args
    # TODO: Autogen

    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare OPT_HEAD OPT_TAIL
    declare DEFAULT_HEAD='---'
    declare -a ARG_FILE

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        --head=*  )
          [[ -n ${OPT_HEAD} ]] && ERRBAG+=("Single occurrence allowed: '${1%%=*}'.")
          OPT_HEAD="${1#*=}"
          ;;
        --head    )
          [[ -n ${OPT_HEAD} ]] && ERRBAG+=("Single occurrence allowed: '${1}'.")
          [[ -n "${2+x}" ]] || ERRBAG+=("Value required: '${1}'.")
          OPT_HEAD="${2}"
          shift
          ;;
        --tail=*  )
          [[ -n ${OPT_TAIL} ]] && ERRBAG+=("Single occurrence allowed: '${1%%=*}'.")
          OPT_TAIL="${1#*=}"
          ;;
        --tail    )
          [[ -n ${OPT_TAIL} ]] && ERRBAG+=("Single occurrence allowed: '${1}'.")
          [[ -n "${2+x}" ]] || ERRBAG+=("Value required: '${1}'.")
          OPT_TAIL="${2}"
          shift
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done

    [[ -n "${OPT_HEAD}" ]] || OPT_HEAD="${DEFAULT_HEAD}"

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      ## TODO: print help
      # SOME IMPLEMENTATION
      # return 0

      log_fuck 'Not implemented yet: `--help`'.
      return 2
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    [[ -n "${OPT_TAIL}" ]] || OPT_TAIL="${OPT_HEAD}"

    printf -- '%s\n' "${OPT_HEAD}"
    SHLIB_LOG_CALLER="${SHLIB_LOG_CALLER-${FUNCNAME[0]}}" \
      cati "${ARG_FILE[@]}" | text_ensure_nl
    printf -- '%s\n' "${OPT_TAIL}"
  } # Body
}
