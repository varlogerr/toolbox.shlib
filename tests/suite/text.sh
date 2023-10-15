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
  declare FIXTURES_DIR; FIXTURES_DIR="$(dirname -- "${BASH_SOURCE[0]}")/../fixture"
} # Fixtures

#
# TESTING
#

_test_text_ensure_nl() {
  unset "${FUNCNAME[0]}"
  declare CMD="${FUNCNAME[0]#_test_*}"
  declare WARN_PREFIX="${CMD} [WARN]:"
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t "Ensures new line from single file" \
      -o 'Foo' \
    "${CMD}" <(printf 'Foo')

  shlib_test -t 'Ensures new line from multi-files' \
      -o "Foo" -o "bar" -o "baz" \
    "${CMD}" <(printf '%s\n%s' 'Foo' 'bar') <(printf '%s' 'baz')

  printf 'Foo' \
  | shlib_test -t 'Ensures new line from stdin' \
      -o "Foo" \
    "${CMD}"

  shlib_test -t 'Ends options' \
      -e "${WARN_PREFIX} Can't read the file: '--help'." \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "No output on empty stdin" \
    "${CMD}"

  shlib_test -t "Ensures new line on empty line input" \
      -o '' \
    "${CMD}" <<< ''

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Warns on non-existing file" \
      -e "${WARN_PREFIX} Can't read the file: '/dev/null/foo'." \
    "${CMD}" /dev/null/foo

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid
}; _test_text_ensure_nl

_test_text_fmt() {
  unset "${FUNCNAME[0]}"
  declare CMD="${FUNCNAME[0]#_test_*}"
  declare WARN_PREFIX="${CMD} [WARN]:"
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  declare FIXTURES_DIR="${FIXTURES_DIR}/text-strip"
  declare -A INP; INP=(
    [one]="${FIXTURES_DIR}/inp1.txt"
    [two]="${FIXTURES_DIR}/inp2.txt"
  )
  declare -A EXP; EXP=(
    [one]="$(cat -- "${FIXTURES_DIR}/exp1.txt")"
    [two]="$(cat -- "${FIXTURES_DIR}/exp2.txt")"
  )

  shlib_test -t "Formats single line from single file" \
      -o 'foo' \
    "${CMD}" <(echo '  foo  ')

  shlib_test -t 'Formats multi-line from single file' \
      -o "${EXP[one]}" \
    "${CMD}" "${INP[one]}"

  shlib_test -t 'Formats from multi-files' \
      -o "${EXP[one]}" -o "${EXP[two]}" -o 'foo' \
    "${CMD}" "${INP[one]}" "${INP[two]}" <(echo '  foo  ')

  shlib_test -t 'Formats stdin' \
      -o "${EXP[one]}" \
    "${CMD}" <<< "$(cat -- "${INP[one]}")"

  shlib_test -t 'Ends options' \
      -e "${WARN_PREFIX} Can't read the file: '--help'." \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "No output on empty stdin" \
    "${CMD}"

  shlib_test -t "No output on empty line input" \
    "${CMD}" <<< ''

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Warns on non-existing file" \
      -e "${WARN_PREFIX} Can't read the file: '/dev/null/foo'." \
    "${CMD}" /dev/null/foo

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid
}; _test_text_fmt

_test_text_prefix() {
  unset "${FUNCNAME[0]}"
  declare CMD="${FUNCNAME[0]#_test_*}"
  declare WARN_PREFIX="${CMD} [WARN]:"
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t "Default prefixes single line from file" \
      -o '  foo' \
    "${CMD}" <(echo 'foo')

  shlib_test -t "Default prefixes multi-line from file" \
      -o "  foo" -o "  bar" \
    "${CMD}" <(echo "foo${SHLIB_NL}bar")

  shlib_test -t "Default prefixes from multi-files" \
      -o "  foo" -o "  bar" -o "  baz" \
    "${CMD}" <(echo "foo${SHLIB_NL}bar") <(echo "baz")

  shlib_test -t "Default prefixes from stdin" \
      -o "  foo" -o "  bar" -o "  baz" \
    "${CMD}" <<< "foo${SHLIB_NL}bar${SHLIB_NL}baz"

  declare flags=('--prefix ' '--prefix=')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Custom prefixes ($f)" \
        -o "/&/&foo" -o "/&/&bar" \
      "${CMD}" ${f}'/&' <<< "foo${SHLIB_NL}bar"
  done

  declare flags=('-c ' '--count ' '--count=')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Custom count ($f)" \
        -o " foo" -o " bar" \
      "${CMD}" ${f}1 <<< "foo${SHLIB_NL}bar"
  done

  shlib_test -t 'Ends options' \
      -e "${WARN_PREFIX} Can't read the file: '--help'." \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "No output on empty stdin" \
    "${CMD}"

  shlib_test -t "Outputs prefixed empty line on empty line input" \
      -o '' \
    "${CMD}" <<< ''

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Warns on non-existing file" \
      -e "${WARN_PREFIX} Can't read the file: '/dev/null/foo'." \
    "${CMD}" /dev/null/foo

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''

  shlib_test -t "Fails on duplicated option" \
      -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '--count'." \
    "${CMD}" -c 1 --count=2 ''

  shlib_test -t "Fails on invalid count value" \
      -c 2 -e "${FAIL_PREFIX} Invalid value: '-c .'." \
    "${CMD}" -c '.' ''

  declare flags=('-c' '--prefix')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Fails on absent option value (${f})" \
        -c 2 -e "${FAIL_PREFIX} Value required: '${f}'." \
      "${CMD}" '' "${f}"
  done
}; _test_text_prefix

_test_text_tpl() {
  unset "${FUNCNAME[0]}"
  declare CMD="${FUNCNAME[0]#_test_*}"
  declare WARN_PREFIX="${CMD} [WARN]:"
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  declare FIXTURES_DIR="${FIXTURES_DIR}/text-tpl"
  declare -A INP; INP=(
    [one]="${FIXTURES_DIR}/inp1.txt"
    [two]="${FIXTURES_DIR}/inp2.txt"
  )

  shlib_test -t "Substitutes all occurrences of key from single file (--kv KEY=VAL)" \
      -o 'foo Dude bar {{ DIRECTION }} Dude baz' \
      -o 'Just a line' \
      -o '  Dude foo Dude' \
    "${CMD}" --kv NAME=Dude "${INP[one]}"

  shlib_test -t "Substitutes all keys from single file (--kv KEY VAL, --kv=KEY=VAL)" \
      -o 'foo Dude bar left Dude baz' \
      -o 'Just a line' \
      -o '  Dude foo Dude' \
    "${CMD}" --kv NAME Dude --kv=DIRECTION=left "${INP[one]}"

  shlib_test -t "Substitutes from multi-files" \
      -o 'foo Dude bar {{ DIRECTION }} Dude baz' \
      -o 'Just a line' \
      -o '  Dude foo Dude' \
      -o 'foo Dude bar {{ DIRECTION }} Dude baz' \
      -o 'Just a line' \
      -o '  Dude foo Dude' \
    "${CMD}" --kv NAME=Dude "${INP[one]}" "${INP[one]}"

  shlib_test -t "Substitutes from stdin" \
      -o 'foo Dude bar {{ DIRECTION }} Dude baz' \
      -o 'Just a line' \
      -o '  Dude foo Dude' \
    "${CMD}" --kv NAME=Dude < "${INP[one]}"

  shlib_test -t "Unspaces all on empty value" \
      --skip -o 'foo bar' -o 'foo bar' -o '  foo bar  '\
    "${CMD}" --kv NAME= "${INP[two]}"

  shlib_test -t "Unspaces single on empty value" \
      --skip -o 'foo {{ NAME }} bar {{ NAME }}' \
      -o 'foo bar {{ NAME }}' \
      -o '  foo {{ NAME }} bar {{ NAME }}  '\
    "${CMD}" -f --kv NAME "" "${INP[two]}"

  declare f; for f in -o --only; do
    shlib_test -t "Prints only substitution lines (${f})" \
        -o 'foo Dude bar {{ DIRECTION }} Dude baz' \
        -o '  Dude foo Dude' \
      "${CMD}" --kv NAME=Dude "${f}" "${INP[one]}"
  done

  declare f; for f in -f --first; do
    shlib_test -t "Substitutes only first (${f})" \
        -o 'foo {{ NAME }} bar {{ DIRECTION }} {{ NAME }} baz' \
        -o 'Just a line' \
        -o '  Dude foo {{ NAME }}' \
      "${CMD}" --kv NAME=Dude "${f}" "${INP[one]}"
  done

  declare f; for f in -s --single; do
    shlib_test -t "Substitutes only once (${f})" \
        -o 'foo Dude bar left {{ NAME }} baz' \
        -o 'Just a line' \
        -o '  Dude foo {{ NAME }}' \
      "${CMD}" --kv NAME=Dude --kv DIRECTION=left "${f}" "${INP[one]}"
  done

  declare -a flags=('--brackets ' '--brackets=')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Substitutes with custom brackets (${f})" \
        -o 'foo bar baz' \
      "${CMD}" --kv WHAT=bar ${f}'[KEY]' <<< 'foo [WHAT] baz'
  done

  shlib_test -t "Most restrictive option wins (first over single)" \
      -o 'foo {{ NAME }} bar {{ DIRECTION }} {{ NAME }} baz' \
      -o 'Just a line' \
      -o '  Dude foo {{ NAME }}' \
    "${CMD}" --kv NAME=Dude -s -f "${INP[one]}"

  shlib_test -t 'Ends options' \
      -e "${WARN_PREFIX} Can't read the file: '--help'." \
    "${CMD}" -- --help

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid

  declare -a flags=(-f --first -o --only -s --single)
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Fails on duplicated option (${f})" \
        -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '${f}'." \
      "${CMD}" "${f}" "${f}"
  done

  declare -a seps=(' ' '=')
  declare s; for s in "${seps[@]}"; do
    shlib_test -t "Fails on duplicated option (--brackets${s})" \
        -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '--brackets'." \
      "${CMD}" --brackets${s}'(KEY)' --brackets${s}'(KEY)'
  done

  shlib_test -t "Fails on invalid brackets value (--brackets=)" \
      -c 2 -e "${FAIL_PREFIX} Invalid value: '--brackets=foo'." \
    "${CMD}" --brackets=foo

  shlib_test -t "Fails on invalid brackets value (--brackets)" \
      -c 2 -e "${FAIL_PREFIX} Invalid value: '--brackets'." \
    "${CMD}" --brackets foo

  shlib_test -t "Fails on absent brackets value" \
      -c 2 -e "${FAIL_PREFIX} Value required: '--brackets'." \
    "${CMD}" --brackets

  shlib_test -t "Fails on absent key" \
      -c 2 -e "${FAIL_PREFIX} Key-value required: '--kv'." \
    "${CMD}" --kv

  declare -a flags=('--kv=' '--kv ')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Fails on invalid key-value format ${f}KEY=VALUE" \
        -c 2 -e "${FAIL_PREFIX} Invalid key-value format: '${f}KEYONLY'." \
      "${CMD}" ${f}KEYONLY
  done
}; _test_text_tpl

_test_text_wrap() {
  unset "${FUNCNAME[0]}"
  declare CMD="${FUNCNAME[0]#_test_*}"
  declare WARN_PREFIX="${CMD} [WARN]:"
  declare FAIL_PREFIX="${CMD} [FUCK]:"

  shlib_test -t "Default wrap single line from file" \
      -o '---' -o 'foo' -o '---' \
    "${CMD}" <(echo 'foo')

  shlib_test -t "Default wrap multi-line from file" \
      -o '---' -o 'foo' -o 'bar' -o '---' \
    "${CMD}" <(echo "foo${SHLIB_NL}bar")

  shlib_test -t "Default wrap from multi-files" \
      -o '---' -o 'foo' -o 'bar' -o 'baz' -o '---' \
    "${CMD}" <(echo "foo${SHLIB_NL}bar") <(echo "baz")

  shlib_test -t "Default wrap from stdin" \
      -o '---' -o 'foo' -o 'bar' -o '---' \
    "${CMD}" <<< "foo${SHLIB_NL}bar"

  declare flags=('--head ' '--head=')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Custom head ($f)" \
        -o '^^' -o 'foo' -o 'bar' -o '^^' \
      "${CMD}" ${f}'^^' <<< "foo${SHLIB_NL}bar"
  done

  declare flags=('--tail ' '--tail=')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Custom tail ($f)" \
        -o '---' -o 'foo' -o 'bar' -o ',,' \
      "${CMD}" ${f}',,' <<< "foo${SHLIB_NL}bar"
  done

  shlib_test -t 'Ends options' \
      -o '---' -o '---' \
      -e "${WARN_PREFIX} Can't read the file: '--help'." \
    "${CMD}" -- --help

  printf '' \
  | shlib_test -t "Only wrapper on empty stdin" \
      -o '---' -o '---' \
    "${CMD}"

  printf 'foo' \
  | shlib_test -t "Ensures newline" \
      -o '---' -o 'foo' -o '---' \
    "${CMD}"

  declare flag; for flag in -? --help; do
    shlib_test -t "Prints help (${flag})" \
        --skip -c 0 -o "TBD" \
      "${CMD}" "${flag}"
  done

  shlib_test -t "Warns on non-existing file" \
      -o '---' -o '---' \
      -e "${WARN_PREFIX} Can't read the file: '/dev/null/foo'." \
    "${CMD}" /dev/null/foo

  shlib_test -t "Fails on unexpected option" \
      -c 2 -e "${FAIL_PREFIX} Unexpected option: '--invalid'." \
    "${CMD}" --invalid ''

  shlib_test -t "Fails on duplicated option" \
      -c 2 -e "${FAIL_PREFIX} Single occurrence allowed: '--head'." \
    "${CMD}" --head h1 --head h2

  declare flags=('--head' '--tail')
  declare f; for f in "${flags[@]}"; do
    shlib_test -t "Fails on absent option value (${f})" \
        -c 2 -e "${FAIL_PREFIX} Value required: '${f}'." \
      "${CMD}" "${f}"
  done
}; _test_text_wrap
