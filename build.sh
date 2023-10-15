#!/usr/bin/env bash

declare -g SELF SELF_DIR SELF_TOOL
SELF="${SELF_CQ1E70i3lV4RzcX-${0}}"
SELF_DIR="$(dirname -- "${SELF}")"
SELF_TOOL="$(basename -- "${SELF}")"

{ : ########## CONFBLOCK ##########
  declare -a SOURCES=(
    "${SELF_DIR}/src/lib/base.sh"
    "${SELF_DIR}/src/lib"
  )
  declare -a TESTS=(
    "${SELF_DIR}/tests"
  )
  declare -A TARGET=(
    [tmp_dir]="${SELF_DIR}/tmp"
    [bin_file]="${SELF_DIR}/bin/shlib.sh"
    [bin_tpl]="${SELF_DIR}/src/shlib.tpl.sh"
  )
} ########## CONFBLOCK ##########

if [[ -n "${SELF_CQ1E70i3lV4RzcX}" ]]; then # {{ BLOCK_BUILD_CQ1E70i3lV4RzcX }}
  ###############
  #### BUILD ####
  ###############

  declare TARGET_RAW="${TARGET[tmp_dir]}/build.raw.sh"
  declare TARGET_ANNOTATED="${TARGET[tmp_dir]}/build.annotated.sh"
  declare TARGET_TEST="${TARGET[tmp_dir]}/build.test.sh"

  # : \
  # && build tmp "${TARGET[tmp_dir]}" \
  # && build raw "${TARGET_RAW}" "${SOURCES[@]}" \
  # && build test "${TARGET_TEST}" "${TARGET_RAW}" "${TESTS[@]}" \
  # && ${OPTS[test]} && exit || true \
  # && build bin "${TARGET[bin_file]}" "${TARGET[bin_tpl]}" "${TARGET_RAW}" \
  # && ! ${OPTS[test]} && exit || true \
  # && build release "${TARGET[bin_file]}" "${SELF}" "${OPTS[is_shlib]}" \
  #   SHLIB_VERSION _CQ1E70i3lV4RzcX

  exit $?
fi # {{/ BLOCK_BUILD_CQ1E70i3lV4RzcX }}

#
# Only exec flow after here
#
(return 0 &>/dev/null)

declare -r VERSION_CQ1E70i3lV4RzcX=dev # {{ SHLIB_VERSION /}}

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
    [test]=false
    [noself]=false
    [release]=false
    [version]=false
    [is_shlib]=false
  )

  _iife_opts() {
    while [[ $# -gt 0 ]]; do
      case "${1}" in
        -\?|-h|--help ) OPTS[help]=true ;;
        --noself      ) OPTS[noself]=true ;;
        test          ) OPTS[test]=true ;;
        -r|--release  ) OPTS[release]=true ;;
        -v|--version  ) OPTS[version]=true ;;
        *             ) echo "Unsupported argument: '${1}'."; exit 2 ;;
      esac

      shift; break
    done

    [[ $# -lt 1 ]] || {
      echo "${SELF_TOOL} [FATAL]: Too many arguments." >&2
      exit 2
    }

    #########################
    #### Detect is_shlib ####
    #########################
    : \
    && basename -- "${TARGET[bin_file]}" 2>/dev/null | grep -qFx 'shlib.sh' \
    && basename -- "${TARGET[bin_tpl]}" 2>/dev/null | grep -qFx 'shlib.tpl.sh' \
    && OPTS[is_shlib]=true
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
      Build '${TARGET[bin_file]}' script and update '${TOOLNAME}' with compiled functions
      (works only for shlib project). The sources for build are located in:
    "

    (if ! declare -p SOURCES 2>/dev/null | grep -q '^declare -a'; then
      echo "Script misconfiguration, SOURCES must be present and to be an array!"
    elif [[ ${#SOURCES[@]} -lt 1 ]]; then
      echo "SOURCES is not configured, see SETUP section of the help."
    else
      printf -- '* %s\n' "${SOURCES[@]}"
    fi) | sed 's/^/,  /'

    echo "
     ,
      Although the script is developed and used for shlib project, it's stand
      alone and can be used in other projects.
     ,
      USAGE:
     ,  ${TOOLNAME} OPTION
     ,  ${TOOLNAME} COMMAND
     ,
      OPTIONS:
     ,  -?, -h, --help  Print this help
     ,  -v, --version   Print version
     ,  --noself        Don't update ${SELF} (ignored in not shlib project)
     ,  -r, --release   Build release. Requirements for release:
     ,                  * build script in git repo
     ,                  * the repo is clean, no pending states, divergences,
     ,                    uncommitted changes, etc...
     ,                  * target template contains '# {{ SHLIB_VERSION /}}' tag
     ,
      AVAILABLE COMMANDS:
     ,  test  - Only build until test stage
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

  printf -- '%s\n' "${VERSION_CQ1E70i3lV4RzcX}"
} && exit 0

if [[ -z "${SELF_CQ1E70i3lV4RzcX}" ]]; then
  ##################################
  #### BUILD & EXEC TMP BUILDER ####
  ##################################

  declare SELF_TXT; SELF_TXT="$(cat -- "${SELF}")"
  declare expr; expr="$(
    tag_name=BLOCK_BUILD_CQ1E70i3lV4RzcX
    self_len=$(wc -l < "${SELF}")

    set -o pipefail
    grep -n -m1 -A "${self_len}" '#\s*{{\s*'"${tag_name}"'\s*}}\s*$' <<< "${SELF_TXT}" \
    | grep -m1 -B "${self_len}" '#\s*{{\/\s*'"${tag_name}"'\s*}}\s*$' \
    | sed -e 's/^\([0-9]\+\)[:-].*/\1/' | sed -n '1p;$p' | tr '\n' ',' \
    | sed 's/,\?$/d/'
  )" || {
    echo "${SELF_TOOL} [FATAL]: Can't detect build block lines." >&2
    exit 1
  }

  declare builder; builder="$(set -x
    mktemp --suffix .shlib.build.sh 2>/dev/null || mktemp
  )" && (set -x; chmod 0700 "${builder}")

  sed "${expr}" <<< "${SELF_TXT}" | (cat; echo; echo ". '${SELF}'") \
  | (set -x; tee -- "${builder}" >/dev/null)

  # Run tmp builder with passed rand var name
  SELF_CQ1E70i3lV4RzcX="${BASH_SOURCE[0]}" "${builder}" "${@}"
fi

#
# Only build flow after here
#
[[ -n "${SELF_CQ1E70i3lV4RzcX}" ]] || exit 0

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
  # declare DL_URL="https://raw.githubusercontent.com/varlogerr/toolbox.shlib/${VERSION_CQ1E70i3lV4RzcX}/bin/shlib.sh"

  declare src; src="$(set -x; "${DL_CMD[@]}" "${DL_URL}")" || {
    echo "${SELF_TOOL} [FATAL]: Can't download shlib library." >&2
    exit 2
  }
  # shellcheck disable=SC1090
  . <(cat <<< "${src}")
}
