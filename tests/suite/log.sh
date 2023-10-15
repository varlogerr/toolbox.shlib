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
  . "$(dirname -- "${BASH_SOURCE[0]}")/../fixture/common.sh"

  enable_log_trace() {
    export SHLIB_LOG_TRACE=true
  }

  check_log_trace() {
    declare err; err="$(shlib_test_stderr)"

    declare -i trace_lines; trace_lines="$(
      # shellcheck disable=SC2153
      grep -c -F "${CALLER} [TRACE]: " <<< "${err}"
    )"

    [[ ${trace_lines} -gt 0 ]]; shlib_test_rc $?
  }
} # Fixtures

#
# TESTING
#

declare type
declare caller
declare LOG_PREFIX FAIL_PREFIX
declare CMD; for CMD in \
  log_info log_warn log_fuck log_err log_fatal \
; do
  type="${CMD#*_}"
  caller=shlib_test
  LOG_PREFIX="${caller} [${type^^}]:"
  FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t "Logs on single line arg" \
      -e "${LOG_PREFIX} Foo bar" \
    "${CMD}" "Foo bar"

  shlib_test -t "Logs on multi-line arg" \
      -e "${LOG_PREFIX} Foo" -e "${LOG_PREFIX} bar" \
    "${CMD}" "Foo${SHLIB_NL}bar"

  shlib_test -t "Logs on multi-args" \
      -e "${LOG_PREFIX} Foo" -e "${LOG_PREFIX} bar" -e "${LOG_PREFIX} baz" \
    "${CMD}" "Foo${SHLIB_NL}bar" "baz"

  shlib_test -t "Logs on stdin" \
      -e "${LOG_PREFIX} Foo" -e "${LOG_PREFIX} bar" \
    "${CMD}" <<< "Foo${SHLIB_NL}bar"

  shlib_test -t "Ends options" -e "${LOG_PREFIX} --help" \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "No output on empty stdin" \
    "${CMD}"

  shlib_test -t "Outputs blank error message on empty line input" \
      -e "${LOG_PREFIX} " \
    "${CMD}" ''

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Fails without message" \
      -b mock_timeout -c 2 -e "${FAIL_PREFIX} MSG is required." \
    "${CMD}"

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid <<< ''
done

declare CMD; for CMD in \
  log_err log_fuck log_fatal \
; do
  # CALLER is required by check_log_trace
  CALLER=shlib_test \
  shlib_test -t "Traces error" \
      -E -c 0 -b enable_log_trace -a check_log_trace \
    "${CMD}" <<< "Lolo"
done

declare CMD; for CMD in \
  log_info log_warn \
; do
  # CALLER is required by check_log_trace
  CALLER=shlib_test \
  shlib_test -t "Doesn't trace error" \
      -E -c 1 -b enable_log_trace -a check_log_trace \
    "${CMD}" <<< "Lolo"
done
