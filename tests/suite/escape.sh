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
} # Fixtures

#
# TESTING
#

_test_escape_sed() {
  unset "${FUNCNAME[0]}"
  declare CMD=escape_sed
  declare FAIL_PREFIX="${CMD} [FUCK]:"

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

  shlib_test -t "Fails without text" \
      -b mock_timeout -c 2 -e "${FAIL_PREFIX} TEXT is required." \
    "${CMD}"

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''

  shlib_test -t "Fails on duplicated option" \
      -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '--replace'." \
    "${CMD}" -r --replace ''
}; _test_escape_sed

_test_escape_quote() {
  unset "${FUNCNAME[0]}"
  declare CMD=escape_quote
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t 'Escapes quotes from single line arg' \
      -o 'I say \"foo\"' \
    "${CMD}" 'I say "foo"'

  shlib_test -t 'Escapes quotes from multi-line arg' \
      -o 'I say \"foo\"'"${SHLIB_NL}"'You say \"bar\"' \
    "${CMD}" 'I say "foo"'"${SHLIB_NL}"'You say "bar"'

  shlib_test -t 'Escapes quotes from multi-args' \
      -o 'I say \"foo\"'"${SHLIB_NL}"'You say \"bar\"'"${SHLIB_NL}"'They say \"baz\"' \
    "${CMD}" 'I say "foo"'"${SHLIB_NL}"'You say "bar"' 'They say "baz"'

  shlib_test -t 'Escapes quotes from stdin' \
      -o 'I say \"foo\"'"${SHLIB_NL}"'You say \"bar\"' \
    "${CMD}" <<< 'I say "foo"'"${SHLIB_NL}"'You say "bar"'

  shlib_test -t 'Escapes single quotes from single line arg (-s)' \
      -o "I say '\''foo'\''" \
    "${CMD}" -s "I say 'foo'"

  shlib_test -t 'Escapes single quotes from multi-line arg (--single)' \
      -o "I say '\''foo'\''${SHLIB_NL}You say '\''bar'\''" \
    "${CMD}" --single "I say 'foo'${SHLIB_NL}You say 'bar'"

  shlib_test -t 'Escapes single quotes from multi-args (-s)' \
      -o "I say '\''foo'\''${SHLIB_NL}You say '\''bar'\''${SHLIB_NL}They say '\''baz'\''" \
    "${CMD}" -s "I say 'foo'${SHLIB_NL}You say 'bar'" "They say 'baz'"

  shlib_test -t 'Escapes single quotes from stdin (--single)' \
      -o "I say '\''foo'\''${SHLIB_NL}You say '\''bar'\''" \
    "${CMD}" --single <<< "I say 'foo'${SHLIB_NL}You say 'bar'"

  shlib_test -t 'Does not escape quotes on -s flag' \
      -o 'I say "foo"' \
    "${CMD}" -s 'I say "foo"'

  shlib_test -t 'Does not escape single quotes without -s flag' \
      -o "I say 'foo'" \
    "${CMD}" "I say 'foo'"

  shlib_test -t 'Wraps with quotes from single line arg (-w)' \
      -o '"Foo"' \
    "${CMD}" -w 'Foo'

  shlib_test -t 'Wraps with quotes from multi-line arg (--wrap)' \
      -o '"Foo'"${SHLIB_NL}"'Bar"' \
    "${CMD}" --wrap 'Foo'"${SHLIB_NL}"'Bar'

  shlib_test -t 'Wraps with quotes from multi-args' \
      -o '"Foo'"${SHLIB_NL}"'Bar'"${SHLIB_NL}"'Baz"' \
    "${CMD}" -w 'Foo'"${SHLIB_NL}"'Bar' 'Baz'

  shlib_test -t 'Wraps with quotes from stdin' \
      -o '"I say \"foo\"'"${SHLIB_NL}"'You say \"bar\""' \
    "${CMD}" -w <<< 'I say "foo"'"${SHLIB_NL}"'You say "bar"'

  shlib_test -t 'Wraps with single quotes from single line arg' \
      -o "'Foo'" \
    "${CMD}" -s -w 'Foo'

  shlib_test -t 'Wraps with single quotes from multi-line arg' \
      -o "'Foo${SHLIB_NL}Bar'" \
    "${CMD}" -s -w 'Foo'"${SHLIB_NL}"'Bar'

  shlib_test -t 'Wraps with single quotes from multi-args' \
      -o "'Foo${SHLIB_NL}Bar${SHLIB_NL}Baz'" \
    "${CMD}" -s -w "Foo${SHLIB_NL}Bar" 'Baz'

  shlib_test -t 'Wraps with single quotes from stdin' \
      -o "'I say '\''foo'\''${SHLIB_NL}You say '\''bar'\'''" \
    "${CMD}" -s -w <<< "I say 'foo'${SHLIB_NL}You say 'bar'"

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
      -b mock_timeout -c 2 -e "${FAIL_PREFIX} TEXT is required." \
    "${CMD}"

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''

  shlib_test -t "Fails on duplicated option" \
      -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '--single'." \
    "${CMD}" -s --single ''
}; _test_escape_quote

_test_escape_printf() {
  unset "${FUNCNAME[0]}"
  declare CMD=escape_printf
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t 'Escapes on single line arg' \
      -o 'a\\%%z' \
    "${CMD}" 'a\%z'

  shlib_test -t 'Escapes on multi-line arg' \
      -o 'a\\%%z'"${SHLIB_NL}"'b\\%%y' \
    "${CMD}" 'a\%z'"${SHLIB_NL}"'b\%y'

  shlib_test -t 'Escapes on multi-args' \
      -o 'a\\%%z'"${SHLIB_NL}"'b\\%%y'"${SHLIB_NL}"'c\\%%x' \
    "${CMD}" 'a\%z'"${SHLIB_NL}"'b\%y' 'c\%x'

  shlib_test -t 'Escapes on stdin' \
      -o 'a\\%%z'"${SHLIB_NL}"'b\\%%y' \
    "${CMD}" <<< 'a\%z'"${SHLIB_NL}"'b\%y'

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
      -b mock_timeout -c 2 -e "${FAIL_PREFIX} TEXT is required." \
    "${CMD}"

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''
}; _test_escape_printf
