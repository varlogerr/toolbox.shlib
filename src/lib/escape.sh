# https://stackoverflow.com/a/2705678
escape_sed() {
  { # Args
    # TODO: Autogen

    declare STDIN
    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare OPT_REPLACE=false
    declare -a ARG_TEXT

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -r|--replace  )
          ! ${OPT_REPLACE} && OPT_REPLACE=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_TEXT+=("${1}") ;;
      esac

      shift
    done

    [[ "${#ARG_TEXT[@]}" -gt 0 ]] || {
      declare tmp; tmp="$(timeout 2 grep '')"
      declare RC=$?
      if [[ $RC -eq 0 ]]; then
        ARG_TEXT+=("${tmp}"); STDIN="${tmp}"
      # grep no-match RC is 1, timeout RC is 124 or greater
      elif [[ $RC -gt 1 ]]; then
        ERRBAG+=("TEXT is required.")
      fi
    }

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      if [[ (${#INPUT[@]} -lt 2 && -z "${STDIN+x}") ]]; then
        # TODO: print help
        return 0
      fi

      ERRBAG+=("Help option is incompatible with other options and stdin.")
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    [[ ${#ARG_TEXT[@]} -gt 0 ]] || return 0

    declare rex='[]\/$*.^[]'
    ${OPT_REPLACE} && rex='[\/&]'

    printf -- '%s\n' "${ARG_TEXT[@]}" | sed 's/'"${rex}"'/\\&/g'
  } # Body
}

escape_quote() {
  { # Args
    # TODO: Autogen

    declare STDIN
    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare OPT_SINGLE=false
    declare OPT_WRAP=false
    declare -a ARG_TEXT

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -s|--single   )
          ! ${OPT_SINGLE} && OPT_SINGLE=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -w|--wrap     )
          ! ${OPT_WRAP} && OPT_WRAP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_TEXT+=("${1}") ;;
      esac

      shift
    done

    [[ ${#ARG_TEXT[@]} -gt 0 ]] || {
      declare tmp; tmp="$(timeout 2 grep '')"
      declare RC=$?
      if [[ $RC -eq 0 ]]; then
        ARG_TEXT+=("${tmp}"); STDIN="${tmp}"
      # grep no-match RC is 1, timeout RC is 124 or greater
      elif [[ $RC -gt 1 ]]; then
        ERRBAG+=("TEXT is required.")
      fi
    }

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      if [[ (${#INPUT[@]} -lt 2 && -z "${STDIN+x}") ]]; then
        # TODO: print help
        return 0
      fi

      ERRBAG+=("Help option is incompatible with other options and stdin.")
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    [[ ${#ARG_TEXT[@]} -gt 0 ]] || return 0

    declare -a filter1=(-e 's/"/\\"/g')
    ${OPT_SINGLE} && filter1=(-e "s/'/'\\\\''/g")

    declare -a filter2=(-e 's/^//')
    ${OPT_WRAP} && {
      filter2=(-e '1 s/^/"/' -e '$ s/$/"/')
      ${OPT_SINGLE} && filter2=(-e "1 s/^/'/" -e "$ s/$/'/")
    }

    declare -a filter=(sed "${filter1[@]}" "${filter2[@]}")
    printf -- '%s\n' "${ARG_TEXT[@]}" | "${filter[@]}"
  } # Body
}

# https://unix.stackexchange.com/a/552358
escape_printf() {
  { # Args
    # TODO: Autogen

    declare STDIN
    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare -a ARG_TEXT

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_TEXT+=("${1}") ;;
      esac

      shift
    done

    [[ ${#ARG_TEXT[@]} -gt 0 ]] || {
      declare tmp; tmp="$(timeout 2 grep '')"
      declare RC=$?
      if [[ $RC -eq 0 ]]; then
        ARG_TEXT+=("${tmp}"); STDIN="${tmp}"
      # grep no-match RC is 1, timeout RC is 124 or greater
      elif [[ $RC -gt 1 ]]; then
        ERRBAG+=("TEXT is required.")
      fi
    }

    # Autogen always unless meta-disabled help
    ${_OPT_HELP} && {
      if [[ (${#INPUT[@]} -lt 2 && -z "${STDIN+x}") ]]; then
        # TODO: print help
        return 0
      fi

      ERRBAG+=("Help option is incompatible with other options and stdin.")
    }

    [[ ${#ERRBAG[@]} -gt 0 ]] && { log_fuck -- "${ERRBAG[@]}"; return 2; }
  } # Args

  { # Body
    [[ ${#ARG_TEXT[@]} -gt 0 ]] || return 0

    printf -- '%s\n' "${ARG_TEXT[@]}" | sed -e 's/[\\%]/&&/g'
  } # Body
}
