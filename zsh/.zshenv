# Profiling                                                                 {{{1
# ==============================================================================

# Enable profiling (display report with `zprof`)
zmodload zsh/zprof

# Conditional inclusion                                                     {{{1
# ==============================================================================

# Usage: if-darwin && { echo foo }
function if-darwin() { [[ "$(uname)" == "Darwin" ]]; }
function if-linux() { [[ "$(uname)" == "Linux" ]]; }

# Source script if it exists
# Usage: source-if-exists ".my-functions"
function source-if-exists() {
    local fnam=$1

    if [[ -s "${fnam}" ]]; then
        source "${fnam}"
    fi
}

# Source script if it exists
# Usage: source-or-warn ".my-functions"
function source-or-warn() {
    local fnam=$1

    if [[ -s "${fnam}" ]]; then
        source "${fnam}"
    else
        echo "Skipping sourcing ${fnam} as it does not exist"
    fi
}

# Included scripts                                                          {{{1
# ==============================================================================

# GNU parallel
source-or-warn /opt/homebrew/bin/env_parallel.zsh

# Secrets                           {{{2
# ======================================

source-if-exists "$HOME/.zshenv.secret"

function _assert-variables-defined() {
    local variables=("$@")
    for variable in "${variables[@]}"
    do
        if [[ -z "${(P)variable}" ]]; then
            echo "${variable} is not defined -- please check ~/.zshenv.secret"
        fi
    done
}

EXPECTED_SECRETS=(
    SECRET_ACC_RECS_DEV
    SECRET_ACC_RECS_PROD
    SECRET_NEWRELIC_API_KEY
    SECRET_JIRA_API_KEY
    SECRET_JIRA_USER
)

_assert-variables-defined "${EXPECTED_SECRETS[@]}"

# General settings                                                          {{{1
# ==============================================================================

export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_NONE='\033[0m'
export COLOR_CLEAR_LINE='\r\033[K'