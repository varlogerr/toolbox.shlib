{ # Test function
  demo_escape_sed() {
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

      [[ ${#ERRBAG[@]} -gt 0 ]] && { log_err -- "${ERRBAG[@]}"; return 2; }
    } # Args

    { # Body
      [[ ${#ARG_TEXT[@]} -gt 0 ]] || return 0

      declare rex='[]\/$*.^[]'
      ${OPT_REPLACE} && rex='[\/&]'

      printf -- '%s\n' "${ARG_TEXT[@]}" | sed 's/'"${rex}"'/\\&/g'
    } # Body
  }
} # Test function

#
# -t, --title           Test title
# -b, --before          Before hook function
# -a, --after           After hook function
# -o, --out, --stdout   Expected stdout
# -e, --err, --stderr   Expected stderr
# -c, --rc              Expected RC
# -O, --noout           Ignore stdout check
# -E, --noerr           Ignore stderr check
# -C, --norc            Ignore RC check
#
# shlib_test [-t|--title TEST_TITLE] \
#   [-b|--before BEFORE_FUNC] [-a|--after AFTER_FUNC] \
#   [-o|--out|--stdout EXP_STDOUT] [-e|--err|--stderr EXP_STDERR] \
#   [-c|--rc EXP_RC] [-O|--noout]  [-E|--noerr] [-C|--norc] [--skip] \
# CMD_TO_TEST [CMD_TO_TEST_OPTION]...

{ # Fixtures
  setup_mock_timeout() {
    # Mock to speed up timeout
    timeout() {
      unset "${FUNCNAME[0]}" # aka run once
      /usr/bin/env timeout 0.01 "${@:2}"
    }
  }

  _check_has_line() {
    (set -o pipefail
      shlib_test_stdout | grep -qFx "${1}"
    ); shlib_test_rc $?
  }

  check_has_line_baz() { _check_has_line 'baz'; }
} # Fixtures

#
# TESTING
#

_test_demo_escape_sed() {
  unset "${FUNCNAME[0]}"
  declare CMD=demo_escape_sed

  { # Specific tests
    shlib_test -t 'Escapes expression from single line arg' \
        -o 'a\]\\\/\$\*\.\^\[z' \
      "${CMD}" 'a]\/$*.^[z'

    shlib_test -t 'Escapes expression from multi-line arg' \
        -o 'a\]\\\/\$\*\.\^\[z'"${SHLIB_NL}"'b\\\/y' \
      "${CMD}" 'a]\/$*.^[z'"${SHLIB_NL}"'b\/y'

    shlib_test -t 'Escapes expression from multi-args' \
        -o 'a\]\\\/\$\*\.\^\[z'"${SHLIB_NL}"'b\$\*y'"${SHLIB_NL}"'c\^\[x' \
      "${CMD}" 'a]\/$*.^[z'"${SHLIB_NL}"'b$*y' 'c^[x'

    shlib_test -t 'Escapes expression from stdin' \
        -o 'a\]\\\/\$\*\.\^\[z'"${SHLIB_NL}"'b\$\*y' \
      "${CMD}" <<< 'a]\/$*.^[z'"${SHLIB_NL}"'b$*y'

    shlib_test -t 'Escapes replacement from single line arg (-r)' \
        -o 'a\\\/\&z' \
      "${CMD}" -r 'a\/&z'

    shlib_test -t 'Escapes replacement from multi-line arg (--replace)' \
        -o 'a\\\/\&z'"${SHLIB_NL}"'b\\\/\&y' \
      "${CMD}" --replace 'a\/&z'"${SHLIB_NL}"'b\/&y'

    shlib_test -t 'Escapes replacement from multi-args' \
        -o 'a\\\/\&z'"${SHLIB_NL}"'b\\\/\&y'"${SHLIB_NL}"'c\\\/\&x' \
      "${CMD}" -r 'a\/&z'"${SHLIB_NL}"'b\/&y' 'c\/&x'

    shlib_test -t 'Escapes replacement from stdin' \
        -o 'a\\\/\&z'"${SHLIB_NL}"'b\\\/\&y' \
      "${CMD}" -r <<< 'a\/&z'"${SHLIB_NL}"'b\/&y'

    shlib_test -t 'Does not escape expression on -r flag' \
        -o 'a[]z' \
      "${CMD}" -r 'a[]z'

    shlib_test -t 'Does not escape replacement without -r flag' \
        -o 'a&z' \
      "${CMD}" 'a&z'

    shlib_test --title 'Output contains part of input' \
        --noout --after check_has_line_baz \
      "${CMD}" "Foo${SHLIB_NL}bar" "baz"
  } # Specific tests

  shlib_test -t 'Ends options' \
      -o '--help' \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "No output on empty stdin" \
    "${CMD}"

  shlib_test -t "Outputs empty line on empty line input" \
      -o '' \
    "${CMD}" ''

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Fails without input" \
      -b setup_mock_timeout -c 2 -e "[${CMD}:err] TEXT is required." \
    "${CMD}"

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "[${CMD}:err] Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''

  shlib_test -t "Fails on duplicated option" \
      -c 2 -e "[${CMD}:err] Single occurrence allowed: '--replace'." \
    "${CMD}" -r --replace ''
}; _test_demo_escape_sed
