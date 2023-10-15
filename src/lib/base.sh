##################
#### BASE LIB ####
##################

# {{ SHLIB_KEEP = SHLIB_EXT_VARS }}
  # Robust new line. Reference: https://stackoverflow.com/a/64938613
  declare -g SHLIB_NL; SHLIB_NL="$(printf '\nX')"; SHLIB_NL="${SHLIB_NL%X}"
# {{/ SHLIB_KEEP }}

cati() {
  # { # GNU coreutils version
    # cat -- "${@}" 3>&1 1>&2 2>&3 \
    # | sed -e 's/^[^\:]\+:\s//' -e 's/:\s[^\:]\+$//' \
    # | sed 's/^\(.*\)$/Can'\''t read the file: '\''\1'\''./' \
    # | log_warn 2>&1
  # } 3>&1 1>&2 2>&3 # GNU coreutils version

  declare -a err_filter1=(
    sed
    # Remove 'CMD_NAME: ' (i.e. 'cat: ') prefix and ': SOME ERROR' suffix
    -e 's/^[^\:]\+:\s*//' -e 's/:\s*[^\:]\+$//'
    # Unify file name to 'FILENAME' (in single quotes)
    -e 's/^"\(.*\)"$/'\''\1'\''/' -e "s/^.\+[^']\$/'\\0'/"
    # Ensure 'FILENAME' is preceded by space
    -e "s/^'/ '/"
  )
  declare -a err_filter2=(grep -o " '.*")
  declare -a err_filter3=(sed "s/^\s'\\(.*\\)'$/\1/")

  { # GNU coreutils / BusyBox version
    cat -- "${@}" 3>&1 1>&2 2>&3 \
    | "${err_filter1[@]}" | "${err_filter2[@]}" | "${err_filter3[@]}" \
    | sed 's/^\(.*\)$/Can'\''t read the file: '\''\1'\''./' \
    | log_warn 2>&1
  } 3>&1 1>&2 2>&3 # GNU coreutils / BusyBox version

  [[ "${PIPESTATUS[0]}" -lt 1 ]]
}
