#!/usr/bin/env bash

declare -g SELF SELF_DIR SELF_TOOL
SELF="${SELF_7vXdRl9nbm-${0}}"
SELF_DIR="$(dirname -- "${SELF}")"
SELF_TOOL="$(basename -- "${SELF}")"

{ : ########## CONFBLOCK ##########
  # Sources to be tested, directories or files
  declare -a SOURCES=(
    "${SELF_DIR}/bin/shlib.sh"
  )
  # Suites directory
  declare SUITES_DIR="${SELF_DIR}/tests/suite"
  # Custom demo template, remove or comment if not required
  declare DEMO_TEMPLATE="${SELF_DIR}/tests/demo.suite.sh"
} ########## CONFBLOCK ##########

if [[ -n "${SELF_7vXdRl9nbm}" ]]; then # {{ BLOCK_BUILD_7vXdRl9nbm }}
  "${OPTS[demo]-false}" && {
    if [[ -n "${DEMO_TEMPLATE}" ]]; then
      cat -- "${DEMO_TEMPLATE}" 2>/dev/null || {
        echo "Can't read template file: '${DEMO_TEMPLATE}'" >&2
        exit 2
      }
    else
      shlib_test_gen_demo || exit 2
    fi

    exit 0
  }

  ${OPTS[list]} && ARG_SUITES=()

  declare query=(-name '')
  if [[ ${#ARG_SUITES[@]} -gt 0 ]]; then
    declare tmp; for tmp in "${ARG_SUITES[@]}"; do
      query+=(-o -name "$(basename -- "${tmp}").sh")
    done
  else
    query+=(-o -name '*.sh')
  fi

  declare -a FILES_7vXdRl9nbm
  declare tmp; tmp="$(set -o pipefail
    find "${SUITES_DIR}" -type f "${query[@]}" 2>/dev/null | sort -n
  )" || {
    log_fatal -- "Error scanning suites directory: '${SUITES_DIR}'"
    exit 2
  }
  [[ -n "${tmp}" ]] && mapfile -t FILES_7vXdRl9nbm <<< "${tmp}"
  unset -v tmp query

  ${OPTS[list]} && {
    ##############
    #### LIST ####
    ##############

    [[ ${#FILES_7vXdRl9nbm[@]} -gt 0 ]] && {
      basename -a -s '.sh' -- "${FILES_7vXdRl9nbm[@]}"
    }

    exit 0
  }

  [[ -n "${OPTS[func]}" ]] && {
    SHLIB_TEST_EXACT="${OPTS[func]}"
    export SHLIB_TEST_EXACT
  }

  ##############
  #### TEST ####
  ##############

  # Collect source files
  declare -a SOURCE_FILES tmp_sources
  declare src; for src in "${SOURCES[@]}"; do
    head -c 1 -- "${tmp}" &>/dev/null && {
      # It's a file
      SOURCE_FILES+=("${src}"); continue
    }

    # Probably a directory
    src="$(set -o pipefail; find "${src}" -type f -name '*.sh' | sort -n)" || {
      log_fatal -- "Error parsing source: '${SUITES_DIR}'"
      exit 1
    }

    [[ -n "${src}" ]] && {
      mapfile -t tmp_sources <<< "${src}"
      SOURCE_FILES+=("${tmp_sources[@]}")
    }
  done
  unset -v src tmp_sources

  unset -v SELF SELF_DIR SELF_TOOL SUITES_DIR \
    OPTS ARG_SUITES DEMO_TEMPLATE SOURCES

  (
    # Source files that should be tested
    declare src; for src in "${SOURCE_FILES[@]}"; do
      # shellcheck disable=SC1090
      . "${src}"
    done
    unset -v src SOURCE_FILES

    declare START_7vXdRl9nbm; START_7vXdRl9nbm="$(date +%s.%2N)"
    declare FILE_7vXdRl9nbm; for FILE_7vXdRl9nbm in "${FILES_7vXdRl9nbm[@]}"; do
      # shellcheck disable=SC1090
      . "${FILE_7vXdRl9nbm}"
    done
    declare END; END="$(date +%s.%2N)"

    declare -i RC=0
    declare RESULT=SUCCESS
    # shellcheck disable=SC2154
    [[ ${SHLIB_TEST_STATS_f1GlLuNQHx[KO]} -lt 1 ]] || {
      RESULT=FAILURE
      RC=1
    }

    (
      echo "OK:     ${SHLIB_TEST_STATS_f1GlLuNQHx[OK]}"
      echo "KO:     ${SHLIB_TEST_STATS_f1GlLuNQHx[KO]}"
      echo "SKIP:   ${SHLIB_TEST_STATS_f1GlLuNQHx[SKIP]}"
      echo "TIME:   $(bc <<< "${END} - ${START_7vXdRl9nbm}")"
    ) | text_prefix | text_wrap --head "# { ${RESULT}" --tail "# } ${RESULT}"

    exit $RC
  ); exit $?
fi # {{/ BLOCK_BUILD_7vXdRl9nbm }}

#
# Only exec flow after here
#
(return 0 &>/dev/null)

declare -r VERSION_7vXdRl9nbm=dev # {{ SHLIB_VERSION /}}

###########################################################################
##############################               ##############################
############################## SERVICE BLOCK ##############################
##############################               ##############################
###########################################################################

{
  #####################
  #### DETECT OPTS ####
  #####################

  declare -A OPTS=(
    [help]=false
    [version]=false
    [demo]=false
    [list]=false
  )

  declare -a ARG_SUITES ERRBAG

  _iife_opts() {
    while [[ $# -gt 0 ]]; do
      case "${1}" in
        -\?|--help    ) OPTS[help]=true ;;
        -v|--version  ) OPTS[version]=true ;;
        --demo        ) OPTS[demo]=true ;;
        -l|--list     ) OPTS[list]=true ;;
        -f|--func     ) OPTS[func]="${2}"; shift ;;
        --func=*      ) OPTS[func]="${1#*=}" ;;
        -*            ) ERRBAG+=("Invalid option: '${1}'") ;;
        *             ) ARG_SUITES+=("${1}") ;;
      esac

      shift
    done

    [[ ${#ERRBAG[@]} -lt 1 ]] || {
      printf -- "${SELF_TOOL} [FATAL]:"' %s\n' "${ERRBAG[@]}"
      exit 2
    } >&2
  }; _iife_opts "${@}"; unset _iife_opts
}

${OPTS[help]} && { :
  ##############
  #### HELP ####
  ##############

  # shellcheck disable=SC2030
  TOOLNAME="$(basename -- "${SELF}")"
  {
    echo "
      Tests runner. The suites for test are located in:
    "

    [[ -n "${SUITES_DIR+x}" ]] && {
      printf -- '%s\n' "${SUITES_DIR}" | sed 's/^/,  /'
    } || {
      echo "SUITES_DIR is not configured, see SETUP section of the help." | sed 's/^/,  /'
    }

    echo "
     ,
      Although the script is developed and used for shlib project, it's stand
      alone and can be used in other projects.
     ,
      USAGE:
     ,  ${TOOLNAME} OPTION
     ,  ${TOOLNAME} SUITE...
     ,
      OPTIONS:
     ,  -?, -h, --help  Print this help
     ,  -v, --version   Print version
     ,  --demo          Generate demo suite to stdout
     ,  -l, --list      List available suites
     ,  -f, --func      Limit tests to a specific function
     ,
      SETUP:
     ,  Place '${SELF}' script to your project directory, configure
     ,  CONFBLOCK section and \`${SELF}\`.
    "
  } | grep -v '^ *$' | sed -e 's/^ \+//' -e 's/^,//'
} && exit 0

${OPTS[version]} && { :
  #################
  #### VERSION ####
  #################

  printf -- '%s\n' "${VERSION_7vXdRl9nbm}"
} && exit 0

if [[ -z "${SELF_7vXdRl9nbm}" ]]; then
  ##################################
  #### BUILD & EXEC TMP BUILDER ####
  ##################################

  declare SELF_TXT; SELF_TXT="$(cat -- "${SELF}")"
  declare expr; expr="$(
    tag_name=BLOCK_BUILD_7vXdRl9nbm
    self_len=$(wc -l < "${SELF}")

    set -o pipefail
    grep -n -m1 -A "${self_len}" '#\s*{{\s*'"${tag_name}"'\s*}}\s*$' <<< "${SELF_TXT}" \
    | grep -m1 -B "${self_len}" '#\s*{{\/\s*'"${tag_name}"'\s*}}\s*$' \
    | sed -e 's/^\([0-9]\+\)[:-].*/\1/' | sed -n '1p;$p' | tr '\n' ',' \
    | sed 's/,\?$/d/'
  )" || {
    echo "${SELF_TOOL} [FATAL]: Can't detect build block lines."
    exit 1
  }

  declare builder; builder="$(
    mktemp --suffix .shlib.build.sh 2>/dev/null || mktemp
  )" && (chmod 0700 "${builder}")

  sed "${expr}" <<< "${SELF_TXT}" | (cat; echo; echo ". '${SELF}'") \
  | (tee -- "${builder}" >/dev/null)

  # Run tmp builder with passed rand var name
  SELF_7vXdRl9nbm="${BASH_SOURCE[0]}" "${builder}" "${@}"
  exit $?
fi

#
# Only build flow after here
#
[[ -n "${SELF_7vXdRl9nbm}" ]] || exit 0

{
  declare -a DL_CMD=(wget -q -O -)
  "${DL_CMD[@]}" --version &>/dev/null || {
    DL_CMD=(curl -sL); "${DL_CMD[@]}" --version &>/dev/null
  } || {
    echo "${SELF_TOOL} [FATAL]: Download tool required: curl or wget." >&2
    exit 2
  }

  # TODO: fix url to the tool version
  declare DL_URL="https://raw.githubusercontent.com/varlogerr/toolbox.shlib/dev/bin/shlib.sh"
  # declare DL_URL="https://raw.githubusercontent.com/varlogerr/toolbox.shlib/${VERSION_7vXdRl9nbm}/bin/shlib.sh"

  declare src; src="$("${DL_CMD[@]}" "${DL_URL}")" || {
    echo "${SELF_TOOL} [FATAL]: Can't download shlib library." >&2
    exit 2
  }

  # TODO: fix to `. <(cat <<< "${src}")`
  # shellcheck disable=SC1090
  . "${SELF_DIR}/src/_.sh"
}
