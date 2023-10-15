# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  # Logger name
  declare -g SHLIB_LOG_CALLER
  # Output error trace to stderr
  declare -g SHLIB_LOG_TRACE="${SHLIB_LOG_TRACE-false}"
# {{/ SHLIB_KEEP }}

log_info()  { TYPE=info   TRACEABLE=false _log_type "${@}"; }
log_warn()  { TYPE=warn   TRACEABLE=false _log_type "${@}"; }
log_fuck()  { TYPE=fuck   TRACEABLE=true  _log_type "${@}"; }
log_err()   { TYPE=err    TRACEABLE=true  _log_type "${@}"; }
log_fatal() { TYPE=fatal  TRACEABLE=true  _log_type "${@}"; }

_log_type() {
  { # Args
    # TODO: Autogen

    declare STDIN
    declare -a ERRBAG
    declare -a INPUT=("${@}")

    declare _OPT_ENDOPTS=false
    declare _OPT_HELP=false

    declare -a ARG_MSG

    declare arg; while [[ $# -gt 0 ]]; do
      ${_OPT_ENDOPTS} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) _OPT_ENDOPTS=true ;;
        -\?|-h|--help )
          ! ${_OPT_HELP} && _OPT_HELP=true \
          || ERRBAG+=("Single occurrence allowed: '${1}'.")
          ;;
        -* ) ERRBAG+=("Unexpected option: '${1}'.") ;;
        *  ) ARG_MSG+=("${1}") ;;
      esac

      shift
    done

    [[ "${#ARG_MSG[@]}" -gt 0 ]] || {
      declare tmp; tmp="$(timeout 2 grep '')"
      declare RC=$?
      if [[ $RC -eq 0 ]]; then
        ARG_MSG+=("${tmp}"); STDIN="${tmp}"
      # grep no-match RC is 1, timeout RC is 124 or greater
      elif [[ $RC -gt 1 ]]; then
        ERRBAG+=("MSG is required.")
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

    [[ ${#ERRBAG[@]} -gt 0 ]] && {
      SHLIB_LOG_CALLER="${FUNCNAME[1]}" log_fuck -- "${ERRBAG[@]}"
      return 2
    }
  } # Args

  { # Body
    [[ ${#ARG_MSG[@]} -gt 0 ]] || return 0

    declare CALLER="${SHLIB_LOG_CALLER:-${FUNCNAME[2]}}"

    # declare PREFIX="[${CALLER}${CALLER:+:}${TYPE}] "
    declare PREFIX="${CALLER}${CALLER:+ }[${TYPE^^}]: "
    printf -- "%s\n" "${ARG_MSG[@]}" \
    | text_prefix -c 1 --prefix "${PREFIX}" >&2

    if [[ "${SHLIB_LOG_TRACE,,}" =~ ^(1|yes|true)$ ]] && ${TRACEABLE}; then
      declare -a ftrace=("${FUNCNAME[@]:2}")
      declare -a ltrace=("${BASH_LINENO[@]:1}"); unset 'ltrace[-1]'
      declare -a trace

      declare ix; for ix in "${!ftrace[@]}"; do
        trace+=("${ftrace[$ix]}:${ltrace[$ix]}")
      done

      [[ ${#trace[@]} -gt 0 ]] || return 0

      SHLIB_LOG_TRACE=false TYPE=trace SHLIB_LOG_CALLER="${CALLER}" \
        "${FUNCNAME[0]}" -- "${trace[@]}"
    fi
  } # Body
}
