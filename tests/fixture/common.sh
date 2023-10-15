mock_timeout() {
  # Mock to speed up timeout
  timeout() {
    unset "${FUNCNAME[0]}" # aka run once
    /usr/bin/env timeout 0.01 "${@:2}"
  }
}
