autoload -Uz compinit

# If you come from bash you might have to change your $PATH.
export PATH=/opt/homebrew/bin:$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export FZF_BASE=/usr/local/opt/fzf/install

# Default editor
export EDITOR="nano"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode auto      # update automatically without asking

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 2

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  bgnotify
  colorize
  fzf
  git
  github
  direnv
  dotenv
  jira
  kubectl
  macos
  sbt
  scala
  themes
  z
)

source $ZSH/oh-my-zsh.sh

# User configuration

DEFAULT_USER prompt_context(){}

# SSH
export SSH_AUTH_SOCK="$HOME/.ssh/agent-socket"
ssh-add -l >& /dev/null
if [[ $? -eq 2 ]]
then
  rm -f "$SSH_AUTH_SOCK"
  eval $(ssh-agent -a "$SSH_AUTH_SOCK")
  ssh-add -k $HOME/.ssh/recs-*.id_rsa
fi

# Aliases                                                                   {{{1
# ==============================================================================                                                             # Grep

# Better command defaults
alias env='env | sort'                                                      # env should be sorted
alias tree='tree -A'                                                        # tree should be ascii
alias entr='entr -c'                                                        # entr should be colourised
alias sed='gsed'                                                            # Use gsed instead of sed
alias date='gdate'                                                          # Use gdate instead of date

# Other useful stuff
alias reload-zsh-config="exec zsh"                                          # Reload Zsh config
alias zsh-startup='time  zsh -i -c exit'                                    # Display Zsh start-up time
alias display-colours='msgcat --color=test'                                 # Display terminal colors
alias list-ports='netstat -anv'                                             # List active ports


# IntelliJ and Pycharm                                                      {{{1
# ==============================================================================

# function _launch-jetbrains-tool() {
#     local cmd=$1
#     shift
#     local args=$@
#
#     if [[ $# -eq 0 ]] ; then
#         args='.'
#     fi
#
#     zsh -c "${cmd} ${args} > /dev/null 2>&1 &"
# }
# compdef _files _launch-jetbrains-tool
#
# alias charm='_launch-jetbrains-tool pycharm'                                # Launch PyCharm
# alias idea='_launch-jetbrains-tool idea'                                    # Launch IntelliJ

# General functions                                                         {{{1
# ==============================================================================

# Useful things to pipe into        {{{2
# ======================================

alias fmt-xml='xmllint --format -'                                          # Prettify XML (cat foo.xml | fmt-xml)
alias fmt-json='jq "."'                                                     # Prettify JSON (cat foo.json | fmt-json)
alias tabulate-by-tab="gsed 's/\t\t/\t-\t/g' | column -t -s \$'\t'"         # Tabluate TSV (cat foo.tsv | tabulate-by-tab)
alias tabulate-by-comma="gsed 's/,,/,-,/g' | column -t -s '','' "           # Tabluate CSV (cat foo.csv | tabulate-by-comma)
alias tabulate-by-space='column -t -s '' '' '                               # Tabluate CSV (cat foo.txt | tabulate-by-space)
alias as-stream='stdbuf -o0'                                                # Turn pipes to streams (tail -F foo.log | as-stream grep "bar")
alias strip-color="gsed -r 's/\x1b\[[0-9;]*m//g'"                           # Strip ANSI colour codes (some-cmd | strip-color)
alias strip-ansi="perl -pe 's/\x1b\[[0-9;]*[mG]//g'"                        # Strip all ANSI control codes (some-cmd | strip-ansi)
alias strip-quotes='gsed "s/[''\"]//g"'                                     # Strip all quotes (some-cmd | strip-quotes)
alias sum-of="paste -sd+ - | bc"                                            # Sum numbers from stdin (some-cmd | sum-of)

alias csv-to-json="python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))'"
alias json-to-csv='jq -r ''(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv'''

# File helpers                      {{{2
# ======================================

# Display the full path of a file
# full-path ./foo.txt
function full-path() {
    declare fnam=$1

    if [ -d "$fnam" ]; then
        (cd "$fnam"; pwd)
    elif [ -f "$fnam" ]; then
        if [[ $fnam == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$fnam"
        fi
    fi
}

# Tar a file
# tarf my-dir
function tarf() {
    declare fnam=$1
    tar -zcvf "${fnam%/}".tar.gz "$1"
}

# Untar a file
# untarf my-dir.tar.gz
function untarf() {
    declare fnam=$1
    tar -zxvf "$1"
}

# Long running jobs                 {{{2
# ======================================

# Notify me when something completes
# Usage: do-something-long-running ; tell-me "optional message"
function tell-me() {
    exitCode="$?"

    if [[ $exitCode -eq 0 ]]; then
        exitStatus="SUCCEEDED"
    else
        exitStatus="FAILED"
    fi

    if [[ $# -lt 1 ]] ; then
        msg="${exitStatus}"
    else
        msg="${exitStatus} : $1"
    fi

    if-darwin && {
        osascript -e "display notification \"$msg\" with title \"tell-me\""
    }

    if-linux && {
        notify-send -t 2000 "tell-me" "$msg"
    }
}

# Helper function to notify when the output of a command changes
# Usage:
#   function watch-directory() {
#       f() {
#           ls
#       }
#
#       notify-on-change f 1 "Directory contents changed"
#   }
function notify-on-change() {
    local f=$1
    local period=$2
    local message=$3
    local tmpfile=$(mktemp)

    $f > "${tmpfile}"

    {
        while true
        do
            sleep ${period}
            (diff "${tmpfile}" <($f)) || break
        done

        tell-me "${message}"
    } > /dev/null 2>&1 & disown
}

# Miscellaneous utilities           {{{2
# ======================================

# Prompt for confirmation
# confirm "Delete [y/n]?" && rm -rf *
function confirm() {
    read response\?"${1:-Are you sure?} [y/N] "
    case "$response" in
        [Yy][Ee][Ss]|[Yy])
            true ;;
        *)
            false ;;
    esac
}

# Read HEREDOC into a variable
# read-heredoc myVariable <<'HEREDOC'
# this is
# multiline text
# HEREDOC
# echo $myVariable
function read-heredoc() {
    local varName=${1:-reply}
    shift

    local newlineChar=$'\n'

    local value=""
    while IFS="${newlineChar}" read -r line; do
        value="${value}${line}${newlineChar}"
    done

    eval ${varName}'="${value}"'
}

# Highlight output using sed regex
# cat my-log.txt | highlight red ERROR | highlight yellow WARNING
function highlight() {
    if [[ $# -ne 2 ]] ; then
        echo 'Usage: highlight COLOR PATTERN'
        echo '  COLOR   The color to use (red, green, yellow, blue, magenta, cyan)'
        echo '  PATTERN The sed regular expression to match'
        return 1
    fi

    color=$1
    pattern=$2

    declare -A colors
    colors[red]="\033[0;31m"
    colors[green]="\033[0;32m"
    colors[yellow]="\033[0;33m"
    colors[blue]="\033[0;34m"
    colors[magenta]="\033[0;35m"
    colors[cyan]="\033[0;36m"
    colors[default]="\033[0m"

    colorOn=$(echo -e "${colors[$color]}")
    colorOff=$(echo -e "${colors[default]}")

    gsed -u s"/$pattern/$colorOn\0$colorOff/g"
}
compdef '_alternative \
    "arguments:custom arg:(red green yellow blue magenta cyan)"' \
    highlight

# Convert milliseconds since the epoch to the current date time
# echo 1633698951550 | epoch-to-date
function epoch-to-date() {
    while IFS= read -r msSinceEpoch; do
        awk -v t="${msSinceEpoch}" 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", t/1000); }'
    done
}

# Calculate the result of an expression
# calc 2 + 2
function calc () {
    echo "scale=2;$*" | bc | sed 's/\.0*$//'
}

# Switch between SSH configs
function ssh-config() {
    mv ~/.ssh/config ~/.ssh/config.bak
    ln -s "$HOME/.ssh/config-${1}" ~/.ssh/config
}
compdef '_alternative \
    "arguments:custom arg:(recs)"' \
    ssh-config

# Copy my base machine config to a remote host
function scp-skeleton-config() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: scp-skeleton-config HOST'
        exit -1
    fi

    pushd ~/Developer/tessahoad/dotfiles/skeleton-config || exit 1
    echo "Uploading config to $1"
    for file in $(find . \! -name .); do
        scp $file $1:$file
    done
    popd || exit 1
}
compdef _ssh scp-skeleton-config=ssh

# function install-java-certificate() {
#     if [[ $# -ne 1 ]] ; then
#         echo 'Usage: install-java-certificate FILE'
#         return 1
#     fi
#
#     local certificate=$1
#
#     local keystores=$(find /Library -name cacerts | grep JavaVirtualMachines)
#     while IFS= read -r keystore; do
#         echo
#         echo sudo keytool -importcert -file \
#             "${certificate}" -keystore "${keystore}" -alias Zscalar
#
#         # keytool -list -keystore "${keystore}" | grep -i zscalar
#     done <<< "${keystores}"
# }

function certificate-java-list() {
    local defaultPassword=changeit

    local rootPathsToCheck=(
        /Library
        /Applications/DBeaver.app
    )

    for rootPath in "${rootPathsToCheck[@]}"
    do
        local keystores=$(find ${rootPath} -name cacerts)
        while IFS= read -r keystore; do
            echo
            echo "${keystore}"
            local output=$(keytool -storepass ${defaultPassword} -keystore "${keystore}" -list)
            echo "${output}" | highlight blue '.*'
        done <<< "${keystores}"
    done
}

function certificate-java-install() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: certificate-java-install FILE'
        echo
        echo 'Example:'
        echo 'certificate-java-install /Users/white1/Dev/certificates/ZscalerRootCertificate-2048-SHA256.crt'
        echo 'Default keystore password is changeit'
        return 1
    fi

    local certFile=$1
    local certAlias=$(basename ${certFile})
    local defaultPassword=changeit

    local rootPathsToCheck=(
        /Library
        /Applications/DBeaver.app
    )

    for rootPath in "${rootPathsToCheck[@]}"
    do
        local keystores=$(find ${rootPath} -name cacerts)
        while IFS= read -r keystore; do
            echo
            echo "Checking ${keystore}"
            local output=$(keytool -storepass ${defaultPassword} -keystore "${keystore}" -list -alias ${certAlias})
            if [[ ${output} =~ 'trustedCertEntry' ]]; then
                msg-success "Certificate present"
            else
                msg-error "Certificate missing -- run the following to install"
                echo sudo keytool \
                    -storepass ${defaultPassword} \
                    -keystore "${keystore}" \
                    -importcert \
                    -file "${certFile}" \
                    -alias ${certAlias} \
                    -noprompt
            fi
        done <<< "${keystores}"
    done
}

# Specific tools                                                            {{{1
# ==============================================================================


# jq                                {{{2
# ======================================

# Display the paths to the values in the JSON
# cat foo.json | jq-paths
function jq-paths() {
    # Taken from https://github.com/stedolan/jq/issues/243
    jq '[path(..)|map(if type=="number" then "[]" else tostring end)|join(".")|split(".[]")|join("[]")]|unique|map("."+.)|.[]'
}

# Git                               {{{2
# ======================================

export GIT_TRUNK=main

function git-set-trunk() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-set-trunk GIT_TRUNK'
        return 1
    fi

    export GIT_TRUNK=$1
    echo "GIT_TRUNK set to ${GIT_TRUNK}"
}
compdef "_arguments \
    '1:branch arg:(main master)'" \
    git-set-trunk

# For each directory within the current directory, if the directory is a Git
# repository then execute the supplied function
function git-for-each-repo() {
    setopt local_options glob_dots
    for fnam in *; do
        if [[ -d $fnam ]]; then
            pushd "$fnam" > /dev/null || return 1
            if git rev-parse --git-dir > /dev/null 2>&1; then
                "$@"
            fi
            popd > /dev/null || return 1
        fi
    done
}

# For each directory within the current directory, if the directory is a Git
# repository then execute the supplied function in parallel
function git-for-each-repo-parallel() {
    local dirs=$(find . -maxdepth 1 -type d)

    echo "$dirs" \
        | env_parallel --env "$1" -j5 \
            "
            pushd {} > /dev/null;                               \
            if git rev-parse --git-dir > /dev/null 2>&1; then   \
                $@;                                             \
            fi;                                                 \
            popd > /dev/null;                                   \
            "
}

# For each repo within the current directory, pull the repo
function git-repos-pull() {
    pull-repo() {
        echo "Pulling $(basename $PWD)"
        git pull -r --autostash
        echo
    }

    git-for-each-repo-parallel pull-repo
    git-repos-status
}

# For each repo within the current directory, fetch the repo
function git-repos-fetch() {
    local args=$*

    fetch-repo() {
        echo "Fetching $(basename $PWD)"
        git fetch ${args}
        echo
    }

    git-for-each-repo-parallel fetch-repo
    git-repos-status
}

# Parse Git status into a Zsh associative array
function git-parse-repo-status() {
    local aheadAndBehind
    local ahead=0
    local behind=0
    local added=0
    local modified=0
    local deleted=0
    local renamed=0
    local untracked=0
    local stashed=0

    branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    ([[ $? -ne 0 ]] || [[ -z "$branch" ]]) && branch="unknown"

    aheadAndBehind=$(git status --porcelain=v1 --branch | perl -ne '/\[(.+)\]/ && print $1' )
    ahead=$(echo $aheadAndBehind | perl -ne '/ahead (\d+)/ && print $1' )
    [[ -z "$ahead" ]] && ahead=0
    behind=$(echo $aheadAndBehind | perl -ne '/behind (\d+)/ && print $1' )
    [[ -z "$behind" ]] && behind=0

    # See https://git-scm.com/docs/git-status for output format
    while read -r line; do
      # echo "$line"
      echo "$line" | gsed -r '/^[A][MD]? .*/!{q1}'   > /dev/null && (( added++ ))
      echo "$line" | gsed -r '/^[M][MD]? .*/!{q1}'   > /dev/null && (( modified++ ))
      echo "$line" | gsed -r '/^[D][RCDU]? .*/!{q1}' > /dev/null && (( deleted++ ))
      echo "$line" | gsed -r '/^[R][MD]? .*/!{q1}'   > /dev/null && (( renamed++ ))
      echo "$line" | gsed -r '/^[\?][\?] .*/!{q1}'   > /dev/null && (( untracked++ ))
    done < <(git status --porcelain)

    stashed=$(git stash list | wc -l)

    unset gitRepoStatus
    typeset -gA gitRepoStatus
    gitRepoStatus[branch]=$branch
    gitRepoStatus[ahead]=$ahead
    gitRepoStatus[behind]=$behind
    gitRepoStatus[added]=$added
    gitRepoStatus[modified]=$modified
    gitRepoStatus[deleted]=$deleted
    gitRepoStatus[renamed]=$renamed
    gitRepoStatus[untracked]=$untracked
    gitRepoStatus[stashed]=$stashed
}

# For each repo within the current directory, display the respository status
function git-repos-status() {
    display-status() {
        git-parse-repo-status
        repo=$(basename $PWD)

        local branchColor="${COLOR_RED}"
        if [[ "$gitRepoStatus[branch]" =~ (^main$) ]]; then
            branchColor="${COLOR_GREEN}"
        fi
        local branch="${branchColor}$gitRepoStatus[branch]${COLOR_NONE}"

        local sync="${COLOR_GREEN}in-sync${COLOR_NONE}"
        if (( $gitRepoStatus[ahead] > 0 )) && (( $gitRepoStatus[behind] > 0 )); then
            sync="${COLOR_RED}ahead/behind${COLOR_NONE}"
        elif (( $gitRepoStatus[ahead] > 0 )); then
            sync="${COLOR_RED}ahead${COLOR_NONE}"
        elif (( $gitRepoStatus[behind] > 0 )); then
            sync="${COLOR_RED}behind${COLOR_NONE}"
        fi

        local dirty="${COLOR_GREEN}clean${COLOR_NONE}"
        (($gitRepoStatus[added] + $gitRepoStatus[modified] + $gitRepoStatus[deleted] + $gitRepoStatus[renamed] > 0)) && dirty="${COLOR_RED}dirty${COLOR_NONE}"

        print "${branch},${sync},${dirty},${repo}\n"
    }

    git-for-each-repo display-status | column -t -s ','
}

# For each repo within the current directory, display whether the repo contains
# unmerged branches locally
function git-repos-unmerged-branches() {
    display-unmerged-branches() {
        local cmd="git unmerged-branches"
        unmergedBranches=$(eval "$cmd")
        if [[ $unmergedBranches = *[![:space:]]* ]]; then
            echo "$fnam"
            eval "$cmd"
            echo
        fi
    }

    git-for-each-repo display-unmerged-branches
}

# For each repo within the current directory, display whether the repo contains
# unmerged branches locally and remote
function git-repos-unmerged-branches-all() {
    display-unmerged-branches-all() {
        local cmd="git unmerged-branches-all"
        unmergedBranches=$(eval "$cmd")
        if [[ $unmergedBranches = *[![:space:]]* ]]; then
            echo "$fnam"
            eval "$cmd"
            echo
        fi
    }

    git-for-each-repo display-unmerged-branches-all
}

# For each repo within the current directory, display whether the repo contains
# unmerged branches locally and remote in pretty form
function git-repos-unmerged-branches-all-pretty() {
    display-unmerged-branches-all-pretty() {

        # Handle legacy repos with trunks named 'master'
        if [[ ${inferTrunk} -eq 1 ]]; then
            if [[ -z $(git ls-remote --heads origin main 2>/dev/null) ]]; then
                export GIT_TRUNK=master
            else
                export GIT_TRUNK=main
            fi
        fi

        local cmd="git unmerged-branches-allv"
        unmergedBranches=$(eval "$cmd")
        if [[ $unmergedBranches = *[![:space:]]* ]]; then
            echo "$fnam"
            eval "$cmd"
            echo
        fi
    }

    if [[ $# -eq 1 ]]; then
        if [[ $1 == '--infer-trunk' ]]; then
            local inferTrunk=1
        else
            echo 'Usage: git-repos-unmerged-branches-all-pretty [--infer-trunk]'
            return 1
        fi
    fi

    local originalGitTrunk="${GIT_TRUNK}"

    git-for-each-repo display-unmerged-branches-all-pretty

    export GIT_TRUNK=${originalGitTrunk}
}
compdef "_arguments \
    '1:flags arg:(--infer-trunk)'" \
    git-repos-unmerged-branches-all-pretty

# For each repo within the current directory, display stashes
function git-repos-code-stashes() {
    stashes() {
        local cmd="git stash list"
        local output=$(eval "$cmd")
        if [[ $output = *[![:space:]]* ]]; then
            pwd
            eval "$cmd"
            echo
        fi
    }

    git-for-each-repo stashes
}

# For each repo within the current directory, display recent changes in the
# repo
function git-repos-recent() {
    recent() {
        local cmd='git --no-pager log-recent --perl-regexp --author="^((?!Jenkins).*)$" --invert-grep'
        local output=$(eval "$cmd")
        if [[ $output = *[![:space:]]* ]]; then
            pwd
            eval "$cmd"
            echo
            echo
        fi
    }

    git-for-each-repo recent
}

# For each repo within the current directory, check out the repo for the specified date
function git-repos-checkout-by-date() {
    local date="${1}"

    checkout-by-date() {
        git rev-list -n 1 --before="${date}" origin/main | xargs -I{} git checkout {}
    }

    git-for-each-repo checkout-by-date
}

# For each repo within the current directory, check out trunk
function git-repos-checkout-trunk() {
    local trunk="main"

    checkout-trunk() {
        git checkout "${trunk}"
    }

    git-for-each-repo checkout-trunk
}


# For each repo within the current directory, grep for the argument in the
# history
function git-repos-grep-history() {
    local str=$1

    check-history() {
        local str="$1"
        pwd
        git grep "${str}" $(git rev-list --all | tac)
        echo
    }

    git-for-each-repo-parallel check-history '"'"${str}"'"'
}

# For each repo within the current directory, show the number of lines per
# author
function git-repos-author-line-count() {
    author-line-count() {
        git ls-files \
            | xargs -n1 git blame -w -M -C -C --line-porcelain \
            | sed -n 's/^author //p'
    }

    git-for-each-repo author-line-count | sort -f | uniq -ic | sort -nr
}

# For each repo within the current directory, show the contribution commits per
# author
function git-repos-contributor-stats() {
    contributor-stats() {
        git --no-pager log --format="%aN" --no-merges
    }

    git-for-each-repo contributor-stats | sort | uniq -c | sort -r
}

# Build a list of authors for all repos within the current directory
function git-repos-authors() {
    authors() {
        git --no-pager log | grep "^Author:" | sort | uniq
    }

    git-for-each-repo authors \
        | gsed 's/Author: //' \
        | gsed -r 's/|(\S+), (.+)\([^<]+\)/\2\1/' \
        | sort \
        | uniq
}

# For each repo within the current directory, list the remote
function git-repos-remotes() {
    remotes() {
        git remote -v | grep '(fetch)' | awk '{ print $2 }'
    }

    git-for-each-repo remotes
}

# For each directory within the current directory, generate a hacky lines of
# code count
function git-repos-hacky-line-count() {
    display-hacky-line-count() {
        git ls-files > ../file-list.txt
        lineCount=$(cat < ../file-list.txt | grep -e "\(scala\|py\|js\|java\|sql\|elm\|tf\|yaml\|pp\|yml\)" | xargs cat | wc -l)
        echo "$fnam $lineCount"
        totalCount=$((totalCount + lineCount))
    }

    git-for-each-repo display-hacky-line-count | column -t -s ' ' | sort -b -k 2.1 -n --reverse
}

# Display remote branches which have been merged
function git-merged-branches() {
    git branch -r | xargs -t -n 1 git branch -r --contains
}

# Open the Git repo in the browser
#   Open repo: git-open
#   Open file: git-open foo/bar/baz.txt
function git-open() {
    local filename=$1

    local pathInRepo
    if [[ -n "${filename}" ]]; then
        pushd $(dirname "${filename}")
        pathInRepo=$(git ls-tree --full-name --name-only HEAD $(basename "${filename}"))
    fi

    local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    ([[ $? -ne 0 ]] || [[ -z "$branch" ]]) && branch="main"

    URL=$(git config remote.origin.url)
    echo "Opening '$URL'"

    if [[ $URL =~ ^git@ ]]; then
        [[ -n "${pathInRepo}" ]] && pathInRepo="tree/${branch}/${pathInRepo}"

        local hostAlias=$(echo "$URL" | sed -E "s|git@(.*):(.*).git|\1|")
        local hostname=$(ssh -G "${hostAlias}" | awk '$1 == "hostname" { print $2 }')

        echo "$URL" \
            | sed -E "s|git@(.*):(.*).git|https://${hostname}/\2/${pathInRepo}|" \
            | xargs open

    elif [[ $URL =~ ^https://bitbucket.org ]]; then
        echo "$URL" \
            | sed -E "s|(.*).git|\1/src/${branch}/${pathInRepo}|" \
            | xargs open

    elif [[ $URL =~ ^https://github.com ]]; then
        [[ -n "${pathInRepo}" ]] && pathInRepo="tree/${branch}/${pathInRepo}"
        echo "$URL" \
            | sed -E "s|(.*).git|\1/${pathInRepo}|" \
            | xargs open

    else
        echo "Failed to open due to unrecognised URL '$URL'"
    fi

    [[ -n "${filename}" ]] && popd > /dev/null 2>&1
}

# Archive the Git branch by tagging then deleting it
function git-archive-branch() {
    if [[ $# -ne 1 ]] ; then
        echo 'Archive Git branch by tagging then deleting it'
        echo 'Usage: git-archive-branch BRANCH'
        return 1
    fi

    # git tag archive/$1 $1
    git branch -D $1
}
compdef '_alternative \
  "arguments:custom arg:($(git branch --no-merged ${GIT_TRUNK}))" \
  ' \
  git-archive-branch

# Display the size of objects in the Git log
# https://stackoverflow.com/a/42544963
function git-large-objects() {
    git rev-list --objects --all \
        | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
        | sed -n 's/^blob //p' \
        | sort --numeric-sort --key=2 \
        | cut -c 1-12,41- \
        | $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest
    }

# Rebase the current branch on trunk
function git-rebase-branch-on-trunk() {
    local trunk

    if [ -z "${GIT_TRUNK}" ] ; then
        trunk='main'
    else
        trunk="${GIT_TRUNK}"
    fi

    echo "Rebasing branch on ${trunk}"
    git rebase ${trunk}
}

# Rebase the current branch on trunk and squash the commits
function git-rebase-branch-on-trunk-and-squash-commits() {
    local trunk

    if [ -z "${GIT_TRUNK}" ] ; then
        trunk='main'
    else
        trunk="${GIT_TRUNK}"
    fi

    echo "Rebasing branch on ${trunk} and squashing commits"
    git rebase -i ${trunk}
}

# Display the meaning of characters used for the prompt markers
function git-prompt-help() {
    # TODO: Would be neater to do this dynamically based on info_format
    #       https://github.com/sorin-ionescu/prezto/blob/master/modules/git/functions/git-info
    local promptKey="
    ✚ added
    ⬆ ahead
    ⬇ behind
    ✖ deleted
    ✱ modified
    ➜ renamed
    ✭ stashed
    ═ unmerged
    ◼ untracked
    "
    echo $promptKey
}

# Git stats                         {{{2
# ======================================

# Generate CSV data about a Git repo
function git-generate-stats() {
    local awkScript

    read-heredoc awkScript <<'HEREDOC'
    {
        loc = match($0, /^[a-f0-9]{40}$/)
        if (loc != 0) {
            hash = substr($0, RSTART, RLENGTH)
        }
        else {
            if (match($0, /^$/) == 0) {
                print hash "," $0
            }
        }
    }
HEREDOC

    hashToFileCsvFilename=dataset-hash-to-file.csv

    echo 'hash,file' > "${hashToFileCsvFilename}"
    git --no-pager log --format='%H' --name-only \
        | awk "${awkScript}" \
        >> "${hashToFileCsvFilename}"

    hashToAuthorCsvFilename=dataset-hash-to-author.csv

    local repoName=$(pwd | xargs basename)

    echo 'hash,author,repo_name,commit_date,comment' > "${hashToAuthorCsvFilename}"
    git --no-pager log --format="%H,%aN,${repoName},%cI,'%s'" \
        >> "${hashToAuthorCsvFilename}"

    local sqlScript
    read-heredoc sqlScript <<HEREDOC
        SELECT cf.hash, file, author, repo_name, commit_date, comment
        FROM ${hashToFileCsvFilename} cf INNER JOIN ${hashToAuthorCsvFilename} ca
        ON ca.hash = cf.hash
HEREDOC

    q -d ',' -H -O "${sqlScript}" \
        > .git-stats.csv

    rm "${hashToAuthorCsvFilename}" "${hashToFileCsvFilename}"
}

# Merge CSV data about a Git repo
function git-stats-merge-files() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-merge-files DIR'
        exit -1
    fi

    local dir=$1
    local fnam=".git-stats.csv"

    if [[ -f "${dir}/${fnam}" ]]; then
        cat "${dir}/${fnam}" | tail -n +2 >> "./${fnam}"
    else
        cat "${dir}/${fnam}" > "./${fnam}"
    fi
}

# For each repo within the current directory, generate statistics and merge the files
function git-repos-generate-stats() {
    stats() {
        echo "Getting stats for $(basename $PWD)"
        git-generate-stats

        local fnam=".git-stats.csv"

        if [[ -f "../${fnam}" ]]; then
            cat "${fnam}" | tail -n +2 >> "../${fnam}"
        else
            cat "${fnam}" > "../${fnam}"
        fi

        rm "${fnam}"
    }

    rm -f ".git-stats.csv"

    git-for-each-repo stats
}

# For each repo within the current directory, track all branches
function git-repos-track-and-pull-all() {
    track-and-pull-all() {
        echo "Tracking all branches for $(basename $PWD)"
        git track-all
        git fetch --all
        git pull --all
        echo
    }

    git-for-each-repo track-and-pull-all
}

# For each repo within the current directory, extact the authors and diff with mailmap
function git-mailmap-update() {
    git-repos-authors > .authors.txt
    vim -d .authors.txt ~/.mailmap
}

# TODO: WIP - autoecomplete author names
function _git_stats_authors() {
    q 'select distinct author from .git-stats.csv limit 100' \
        | tail -n +2 \
        | sed -r 's/^(.*)$/"\1"/g' \
        | tr '\n' ' '
}

# TODO: WIP
function whitetest() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-recent-commits-by-author AUTHOR'
        return 1
    fi

    local authorName="$1"
    local cutoff=$(gdate --iso-8601=seconds -u -d "70 days ago")

    q "select * from .git-stats.csv where commit_date > '"${cutoff}"'" \
        | q "select * from - where author in ('"${authorName}"')" \
        | q "select repo_name, file, commit_date from - order by commit_date desc" \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}
compdef _whitetest whitetest
#compdef "_alternative \
#    'arguments:author:($(_git_stats_authors))'" \
#    whitetest
    #
#compdef '_alternative \
#    "arguments:custom arg:(red green yellow blue magenta cyan)"' \
#    whitetest

# For the Git stats in the current directory, display who on the team knows most about a repo
function git-stats-top-team-committers-by-repo() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-top-team-committers-by-repo TEAM'
        return 1
    fi

    local team=$1
    [ "${team}" = 'recs' ]           && teamMembers="'Anamaria Mocanu', 'Rich Lyne', 'Reinder Verlinde', 'Tess Hoad', 'Luci Curnow', 'Andy Nguyen', 'Jerry Yang'"
    [ "${team}" = 'recs-extended' ]  && teamMembers="'Anamaria Mocanu', 'Rich Lyne', 'Reinder Verlinde', 'Tess Hoad', 'Luci Curnow', 'Andy Nguyen', 'Jerry Yang', 'Stu White', 'Dimi Alexiou', 'Ligia Stan'"
    [ "${team}" = 'butter-chicken' ] && teamMembers="'Asmaa Shoala', 'Carmen Mester', 'Colin Zhang', 'Hamid Haghayegh', 'Henry Cleland', 'Karthik Jaganathan', 'Krishna', 'Rama Sane'"
    [ "${team}" = 'spirograph' ]     && teamMembers="'Paul Meyrick', 'Fraser Reid', 'Nancy Goyal', 'Richard Snoad', 'Ayce Keskinege'"
    [ "${team}" = 'dkp' ]            && teamMembers="'Ryan Moquin', 'Gautam Chakraborty', 'Prakruthy Dhoopa Harish', 'Arun Kumar Kalahastri', 'Sangavi Durairaj', 'Vidhya Shaghar A P', 'Suganya Moorthy', 'Chinar Jaiswal'"
    [ "${team}" = 'concept' ]        && teamMembers="'Saad Rashid', 'Benoit Pasquereau', 'Adam Ladly', 'Jeremy Scadding', 'Anique von Berne', 'Nishant Singh', 'Neil Stevens', 'Dominicano Luciano', 'Kanaga Ganesan', 'Akhil Babu', 'Gintautas Sulskus'"

    echo
    echo 'Team'
    while read teamMember
    do
        echo $teamMember
    done < <(echo ${teamMembers} | gsed 's/, /\n/g' | gsed "s/'//g" | sort)

    echo
    echo 'Repos with authors in the team'
    q 'select repo_name, author, count(*) as total from .git-stats.csv group by repo_name, author' \
        | q "select * from - where author in (${teamMembers})" \
        | q 'select *, row_number() over (partition by repo_name order by total desc) as idx from -' \
        | q 'select repo_name, author, total from - where idx <= 5' \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab

    echo
    echo 'Repos with no authors in the team'
    q "select distinct repo_name from .git-stats.csv where author in (${teamMembers})" \
        | q 'select distinct stats.repo_name from .git-stats.csv stats where stats.repo_name not in (select distinct repo_name from -)'
}
compdef "_arguments \
    '1:team arg:(recs recs-extended butter-chicken spirograph dkp concept)'" \
    git-stats-top-team-committers-by-repo

# For the Git stats in the current directory, display all authors
function git-stats-authors() {
    q 'select distinct author from .git-stats.csv order by author asc' \
        | tail -n +2
}

# For the Git stats in the current directory, display the most recent commits
# by each author
function git-stats-most-recent-commits-by-authors() {
    q 'select max(commit_date), author from .git-stats.csv group by author order by commit_date desc' \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}

# For the Git stats in the current directory, display the total number of
# commits by each author
function git-stats-total-commits-by-author() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-total-commits-by-author AUTHOR'
        return 1
    fi

    local authorName=$1

    q 'select repo_name, author, count(*) as total from .git-stats.csv group by repo_name, author' \
        | q "select repo_name, total from - where author in ('"${authorName}"')" \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}

# For the Git stats in the current directory, list the commits for a given author
function git-stats-list-commits-by-author() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-list-commits-by-author AUTHOR'
        return 1
    fi

    local authorName=$1

    q "select * from .git-stats.csv where author in ('"${authorName}"')" \
        | q "select distinct repo_name, commit_date, comment from - order by commit_date desc" \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}

# For the Git stats in the current directory, list the commits for a given
# author by month
function git-stats-total-commits-by-author-per-month() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: git-stats-total-commits-by-author-per-month AUTHOR'
        return 1
    fi

    local authorName=$1

    q "select * from .git-stats.csv where author in ('"${authorName}"')" \
        | q "select distinct repo_name, commit_date from -" \
        | q "select strftime('%Y-%m', commit_date) as 'year_month', count(*) as total from - group by year_month order by year_month desc" \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}

# For the Git stats in the current directory, list the most recent commits for
# each repo
function git-stats-most-recent-commits-by-repo() {
    q -O "select max(commit_date) as last_commit, repo_name from .git-stats.csv where file not in ('version.sbt') group by repo_name order by last_commit desc" \
        | q -D "$(printf '\t')" 'select * from -' \
        | tabulate-by-tab
}

# Java                              {{{2
# ======================================

alias get-java-locations="/usr/libexec/java_home -V"
alias use-java-8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`"

function use-java() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: aws-java (1.8|11|17)"
    else
        declare java_v=$1
        export JAVA_HOME=`/usr/libexec/java_home -v $java_v`
    fi
}

# AWS authentication                {{{2
# ======================================

alias aws-which="env | grep AWS | sort"
alias aws-clear-variables="for i in \$(aws-which | cut -d= -f1,1 | paste -); do unset \$i; done"
alias aws-who-am-i="aws sts get-caller-identity"

function jq-get() {
    declare json=$1 key=$2
    jq -r "$key" <<< "$json"
}

function aws-role() {
    declare accountId=$1 role=$2 profile=$3

    local login_output=$(go-aws-sso assume --account-id $accountId --role-name $role --profile $profile --force --quiet)

    export AWS_ACCESS_KEY_ID=$(jq-get $login_output .AccessKeyId)
    export AWS_REGION=us-east-1
    export AWS_SECRET_ACCESS_KEY=$(jq-get $login_output .SecretAccessKey)
    export AWS_SESSION_TOKEN=$(jq-get $login_output .SessionToken)
    aws-which
}

function aws-recs-login() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: aws-recs-login (dev|staging|live)"
    else
        declare env=$1
        case $env in
            "dev")
                aws-role $SECRET_ACC_RECS_DEV EnterpriseAdmin recs-dev-enterprise-admin
                ;;
            "staging")
                aws-role $SECRET_ACC_RECS_DEV EnterpriseAdmin recs-dev-enterprise-admin
                ;;
            "live")
                aws-role $SECRET_ACC_RECS_PROD EnterpriseAdmin recs-live-enterprise-admin
                ;;
            *)
                echo "Unknown env"
        esac
    fi
}

function aws-shared-search-login() {
if [[ $# -ne 1 ]]; then
        echo "Usage: aws-shared-search-login (dev|cert|staging|live)"
    else
        declare env=$1
        case $env in
            "dev"|"cert"|"staging")
                aws-role $SECRET_ACC_SHARED_SEARCH_DEV EnterpriseAdmin shared-search-dev-enterprise-admin
                ;;
            "live")
                aws-role $SECRET_ACC_SHARED_SEARCH_PROD Developer shared-search-live-developer
                ;;
            *)
                echo "Unknown env"
        esac
    fi
}

alias aws-recs-dev="aws-recs-login dev"
alias aws-recs-staging="aws-recs-login staging"
alias aws-recs-live="aws-recs-login live"
alias aws-shared-search-dev="aws-shared-search-login dev"
alias aws-shared-search-live="aws-shared-search-login live"

function k9s-recs() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: k9s-recs (dev|staging|live) (main|util)"
    else
        declare env=$1 cluster=$2
        export KUBECONFIG=~/.kube/recs-eks-$cluster-$env.conf
        aws-recs-login $env > /dev/null
        k9s
    fi
}

function k9s-kd() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: k9s-kd (dev|cert|staging|live)"
    else
        declare env=$1
        case $env in
            "dev"|"cert")
                export KUBECONFIG=~/.kube/kd-eks-nonprod.conf
                aws-shared-search-login $env > /dev/null
                k9s
                ;;
            "staging")
                export KUBECONFIG=~/.kube/kd-eks-staging.conf
                aws-shared-search-login $env > /dev/null
                k9s
                ;;
            "live")
                export KUBECONFIG=~/.kube/kd-eks-live.conf
                aws-shared-search-login $env > /dev/null
                k9s
                ;;
        *)
            echo "Unknown env"
            ;;
        esac
    fi
}

# AWS helper functions              {{{2
# ======================================

# AWS CLI commands pointing at localstack
alias aws-localstack='aws --endpoint-url=http://localhost:4566'

# List ECR images
aws-ecr-images () {
	local repos=$(aws ecr describe-repositories \
        | jq -r ".repositories[].repositoryName" \
        | sort)
	while IFS= read -r repo
	do
		gecho $repo
		AWS_PAGER="" aws ecr describe-images --repository-name "${repo}" | jq -r '.imageDetails[] | select(has("imageTags")) | .imageTags[] | select(test( "^\\d+\\.\\d+\\.\\d+$" ))' | sort
		gecho
	done <<< "$repos"
}

function aws-bucket-sizes() {
    local endTime=$(date --iso-8601=seconds)
    local startTime=$(date --iso-8601=seconds -d "-2 day")

    local buckets=$(aws s3 ls | cut -d ' ' -f 3)

    while read -r bucketName; do
        local region=$(aws s3api get-bucket-location --bucket ${bucketName} | jq -r ".LocationConstraint")

        if [[ ${region} = "null" ]]; then
            region='us-east-1'
        fi

        local size=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/S3 \
            --start-time ${startTime} \
            --end-time ${endTime} \
            --period 86400 \
            --statistics Average \
            --region ${region} \
            --metric-name BucketSizeBytes \
            --dimensions Name=BucketName,Value=${bucketName} Name=StorageType,Value=StandardStorage \
            | jq ".Datapoints[].Average" \
            | numfmt --to=iec \
        )

        printf "%-7s %-10s %s\n" ${size} ${region} ${bucketName}
    done < <(echo ${buckets})
}


function recs-ecr-login() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: recs-ecr-login (dev|live)"
    else
        local recsEnv=$1
        local region="us-east-1"

        local accountId
        case "${recsEnv}" in
            dev*)
                accountId=$SECRET_ACC_RECS_DEV
            ;;

            live*)
                accountId=$SECRET_ACC_RECS_PROD
            ;;

            *)
                echo "ERROR: Unrecognised environment ${recsEnv}"
                return -1
            ;;
        esac

        aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${accountId}.dkr.ecr.${region}.amazonaws.com"
        echo "Pull images with:"
        echo "  " docker pull "${accountId}.dkr.ecr.${region}.amazonaws.com/IMAGE:VERSION"
    fi
}

# Describe OpenSearch clusters
function aws-opensearch-describe-clusters() {
    while IFS=, read -rA domainName
    do
        aws opensearch describe-domain --domain-name "${domainName}"
    done < <(aws opensearch list-domain-names | jq -r -c '.DomainNames[].DomainName') \
        | jq -s \
        | jq -r '["DomainName", "InstanceType", "InstanceCount", "MasterType", "MasterCount"],(.[].DomainStatus | [.DomainName, (.ClusterConfig | .InstanceType, .InstanceCount, .DedicatedMasterType, .DedicatedMasterCount)]) | @tsv' \
        | tabulate-by-tab
}

# List lambda statuses
function aws-lambda-statuses() {
    aws lambda list-event-source-mappings \
        | jq -r ".EventSourceMappings[] | [.FunctionArn, .EventSourceArn, .State, .UUID] | @tsv" \
        | tabulate-by-tab \
        | sort \
        | highlight red '.*Disabled.*' \
        | highlight yellow '.*\(Enabling\|Disabling\|Updating\).*'
}

# Open the specified S3 bucket in the web browser
function aws-s3-open() {
    local s3Path=$1
    echo "Opening '$s3Path'"
    echo "$s3Path" \
        | gsed -e 's/^.*s3:\/\/\(.*\)/\1/' \
        | gsed -e 's/^/https:\/\/s3.console.aws.amazon.com\/s3\/buckets\//' \
        | gsed -e 's/$/?region=us-east-1/' \
        | xargs open
}

# Display available IPs in each subnet
function aws-subnet-available-ips() {
    aws ec2 describe-subnets \
        | jq -r ".Subnets[] | [ .SubnetId, .AvailableIpAddressCount ] | @tsv" \
        | strip-quotes \
        | tabulate-by-tab
}

# Display service quotas for EC2
function aws-ec2-service-quotas() {
    aws service-quotas list-service-quotas --service-code ec2 \
        | jq -r '(.Quotas[] | ([.QuotaName, .Value])) | @tsv' \
        | strip-quotes \
        | tabulate-by-tab
}

# Download data pipeline definitions to local files
function aws-datapipeline-download-definitions() {
    while IFS=, read -rA x
    do
        pipelineId=${x[@]:0:1}
        pipelineName=$(echo "${x[@]:1:1}" | tr '[A-Z]' '[a-z]' | tr ' ' '-')
        echo $pipelineName
        aws datapipeline get-pipeline-definition --pipeline-id $pipelineId \
            | jq '.' \
            > "pipeline-definition-${pipelineName}"
    done < <(aws datapipeline list-pipelines | jq --raw-output '.pipelineIdList[] | [.id, .name] | @csv' | strip-quotes) \
}

# Display data pipeline instance requirements
function aws-datapipeline-instance-requirements() {
    while IFS=, read -rA x
    do
        pipelineId=${x[@]:0:1}
        pipelineName=${x[@]:1:1}
        aws datapipeline get-pipeline-definition --pipeline-id $pipelineId \
            | jq --raw-output ".values | [\"$pipelineName\", .my_master_instance_type, \"1\", .my_core_instance_type, .my_core_instance_count, .my_env_subnet_private]| @csv"
    done < <(aws datapipeline list-pipelines | jq --raw-output '.pipelineIdList[] | [.id, .name] | @csv' | strip-quotes) \
        | strip-quotes \
        | tabulate-by-comma
}

# Display AWS secrets
function aws-secrets() {
    local secretsNames=$(aws secretsmanager list-secrets | jq -r '.SecretList[].Name')

    while IFS= read -r secret ; do
        echo ${secret}
        aws secretsmanager list-secrets \
            | jq -r ".SecretList[] | select(.Name == \"$secret\") | .Tags[] // [] | select(.Key == \"Description\") | .Value"
        aws secretsmanager get-secret-value --secret-id "$secret"\
            | jq '.SecretString | fromjson'
        echo
    done <<< "${secretsNames}"
}

function aws-ip() {
    local hostname=$1
    echo "${hostname}" | sed -r 's/ip-(.+)\.ec2\.internal/\1/g' | sed -r 's/-/./g'
}

# Docker                            {{{2
# ======================================

function docker-rm-instances() {
    docker ps -a -q | xargs docker stop
    docker ps -a -q | xargs docker rm
}

function docker-rm-images() {
    if confirm; then
        docker-rm-instances
        docker images -q | xargs docker rmi
        docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi
    fi
}

# AMI rotation                      {{{2
# ======================================

alias kube-cycle='docker run -it \
  -v ~/.aws:/home/gopher/.aws \
  -v ${KUBECONFIG}:/home/gopher/.kube/config \
  -e AWS_PROFILE -e AWS_DEFAULT_REGION -e AWS_REGION \
  docker-tiocoreeng-common-virtual.bts.artifactory.tio.systems/kube-cycle'

mute() {
    local nrKeyId=$(aws --region us-east-1 secretsmanager get-secret-value \
    --secret-id recs-newrelic-api-key --query SecretString --output text)

    export API_KEY_REDACTED="${nrKeyId}"

    curl https://api.newrelic.com/graphql \
    -H 'Content-Type: application/json' \
    -H "API-Key: ${API_KEY_REDACTED//[$'\t\r\n ']}" \
    --data-binary "{\"query\":\"mutation {\n  alertsMutingRuleUpdate(rule: {enabled: true}, id: ${SECRET_NEWRELIC_MUTING_RULE_ID}, accountId: ${SECRET_NEWRELIC_ACCOUNT_ID}) {\n    id\n  }\n}\", \"variables\":\"\"}"

    echo 'Muted New Relic Alerts Prod'
}

check_status () {
    # curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.staging.recs.d.elsevier.com/api" 2>/dev/null
    curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.recs.d.elsevier.com/api" 2>/dev/null
    # curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.dev.recs.d.elsevier.com/api" 2>/dev/null
}

unmute() {
    local APIS=(
    article-recommendations-tailored.api
    fi-recommender.api
    library-stats.api
    raven-email-sent-stats.api
    recs-events-service.api
    recs-focus-stats.api
    recs-reviewers-recommender.api
    sd-article-recommendations.api
    sd-logged-email-events.api
    sd-related-articles.api
    sd-user-activity.api
    sd-user-recommendations.api
    )
    (
        for API in "${APIS[@]}"
        do
            status=$(check_status)
            # my_array+=$(curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.recs.d.elsevier.com/api" 2>/dev/null) 
            printf ${API[@]}
            while [[ ${status[@]} =~ 404 ]]
                do 
                    echo "404s, waiting"
                    sleep 60   
                    status=$(check_status)
                    printf ${API[@]}       
                done 
        done
    )


    local nrKeyId=$(aws --region us-east-1 secretsmanager get-secret-value \
    --secret-id recs-newrelic-api-key --query SecretString --output text)

    export API_KEY_REDACTED="${nrKeyId}"

    curl https://api.newrelic.com/graphql \
    -H 'Content-Type: application/json' \
    -H "API-Key: ${API_KEY_REDACTED//[$'\t\r\n ']}" \
    --data-binary "{\"query\":\"mutation {\n  alertsMutingRuleUpdate(rule: {enabled: false}, id: ${SECRET_NEWRELIC_MUTING_RULE_ID}, accountId: ${SECRET_NEWRELIC_ACCOUNT_ID}) {\n    id\n  }\n}\", \"variables\":\"\"}"

    echo 'Unmuted New Relic Alerts Prod'
}

rotation () {
  mute
  kube-cycle --cordon
  unmute
}

# Jira                              {{{2
# ======================================

function jira-my-issues() {
    curl -s -G 'https://elsevier.atlassian.net/rest/api/2/search' \
        --data-urlencode "jql=project=SDPR AND assignee = currentUser() AND status IN (\"In Progress\")" \
        --user "${SECRET_JIRA_USER}:${SECRET_JIRA_API_KEY}" \
        | jq -r ".issues[] | [.key, .fields.summary] | @tsv" \
        | tabulate-by-tab
}

# Recommenders                      {{{2
# ======================================

recs-reviewers-lambda-timings () {
	if [[ $# -ne 1 ]]
	then
		echo "Usage: recs-reviewers-lambda-timings (dev|staging|live)"
	else
		local recsEnv=$1
		awslogs get --no-group --no-stream --timestamp -s "5m" /aws/lambda/recs-reviewers-recommender-lambda-${recsEnv} | grep -e 'Instrumentation\$:' | gsed -r 's/^.* (.+) - ([0-9]+) ms$/\1 \2/' | datamash --sort --field-separator=' ' --round=1 --header-out -g 1 min 2 mean 2 max 2 | column -s ' ' -t
	fi
}

# vim:fdm=marker

# Printing                                                                  {{{1
# ==============================================================================

function start-printer-service() {
    if [[ -n $(ps aux | grep -i 'UniFLOW SmartClient' | grep -v 'grep') ]]; then 
        echo 'Printer service already running'
    else 
        echo 'Starting printer service'
        alias start-printer-service="open /Applications/uniFLOW\ SmartClient.app"
    fi
}

# SSH                                                                       {{{1
# ==============================================================================

function ssh-find-username() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: ssh-find-username ADDRESS'
        return 1
    fi

    local addr=$1

    local USERNAMES=(
        centos
        ec2-user
        hadoop
        admin
    )

    for username in $USERNAMES[@]; do
        printf "${COLOR_CLEAR_LINE}Trying %s" "${username}"
        capturedOutput=$(ssh -q -o ConnectTimeout=5 "${username}@${addr}" "echo 'Test command'" 2>&1)
        exitCode=$?
        if [ $exitCode -eq 0 ]; then
            printf "${COLOR_CLEAR_LINE}${username}\n"
            return 0
        fi
    done
    printf "${COLOR_CLEAR_LINE}Unable to find username for ${addr}\n"
    return 1
}

# Kubernetes                                                                {{{1
# ==============================================================================

source <(kubectl completion zsh)

source <(stern --completion=zsh)

function jira-branch() {
    git checkout -b $1
}
compdef _jira-branch jira-branch


# APIs
# ==============================================================================

function recs-api-statuses() {
    local APIS=(
        article-recommendations-tailored.api
        fi-recommender.api
        library-stats.api
        raven-email-sent-stats.api
        recs-events-service.api
        recs-focus-stats.api
        recs-reviewers-recommender.api
        sd-article-recommendations.api
        sd-hpcc-related-articles.api
        sd-logged-email-events.api
        sd-related-articles.api
        sd-user-activity.api
        sd-user-recommendations.api
    )
    (
        #printf "%s|%s|%s|%s|%s\n" "API" "Dev" "Staging" "Live" "Dev URL"
        printf "%s|%s|%s|%s\n" "API" "Dev" "Live" "Dev URL"
        for API in "${APIS[@]}"
        do
            printf "%s" "${API}"
            curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.dev.recs.d.elsevier.com/api" 2>/dev/null
            #curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.staging.recs.d.elsevier.com/api" 2>/dev/null
            curl -s -w "%{http_code}" -o >(printf "|%s") -X GET "https://${API}.recs.d.elsevier.com/api" 2>/dev/null
            printf "|%s" "https://${API}.dev.recs.d.elsevier.com/api"
            printf "\n"
        done
    ) | column -t -s '|' \
      | highlight red   '\b[045][0-9]\+\b' \
      | highlight green '\b[2][0-9]\+\b'
}

function dkp-api-statuses() {
    local APIS=(
        https://data.elsevier.com/api/
        https://data-dev.elsevier.com/api/
        https://data-sandbox.elsevier.com/api/
        https://prod.topbraid.elsevier.net
    )
    (
        printf "%s|%s|%s|%s\n" "API" "Status" "Endpoint"
        for API in "${APIS[@]}"
        do
            local url="${API}"
            local host=$(echo ${API} | get-hostname)
            printf "%s" "${host}"
            curl --connect-timeout 5 -s -w "%{http_code}" -o >(printf "|%s") -X GET "${url}" 2>/dev/null
            printf "|%s" "${url}"
            printf "\n"
        done
    ) | column -t -s '|' \
      | highlight red   '\b[045][0-9]\+\b' \
      | highlight green '\b[2][0-9]\+\b'
}

function recs-fi-performance() {
    hey -n 20 -c 3 -H 'Accept: application/json' -m GET 'https://fi-recommender.api.recs.d.elsevier.com/api/fi-recommendations/webuser/37325013/author/23982012500'
}


# Dashboards
# ==============================================================================

function recs-reviewers-dashboards() {
    # Obtain the dashboard's GUID:
    #  - Click the "tag" icon by the dashboard's name to access the See metadata and manage tags modal and see the dashboard's GUID.
    local dashboards=(
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjE3Mzg1Njg"   # https://onenr.io/0MRNqLGZGwn
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjE3Mzg1NzA"   # https://onenr.io/0nQx3vAX5jV
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjE3Mzg1Njk"   # https://onenr.io/0VjYnK7ZNQ0
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjkxOTY2MA"    # https://onenr.io/0BQ1p61dbjx
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjI4NTYzNTc"   # https://onenr.io/0bRKaO7GzQE
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfDEwMDA3MTc"       # https://onenr.io/0vwBpGeg1jp
        "MjA5OTI0M3xWSVp8REFTSEJPQVJEfGRhOjQ1MDIzMQ"    # https://onenr.io/0VjYMox9Ej0
    )

    for dashboard in $dashboards[@]; do
        # Find the sub-dashboards in the main page
        subDashboardsResponse=$(curl -s https://api.newrelic.com/graphql \
            -H 'Content-Type: application/json' \
            -H "API-Key: ${SECRET_NEWRELIC_API_KEY}" \
            --data-binary '{"query":"{ actor { entity(guid: \"'${dashboard}'\") { ... on DashboardEntity { guid name pages { guid name } } } } } ", "variables":""}'
        )

        subDashboard=$(echo "${subDashboardsResponse}" | jq -r '.data.actor.entity.pages[0].guid')

        # Generate a new URL for the current data
        dashboardUrlResponse=$(curl -s https://api.newrelic.com/graphql \
            -H 'Content-Type: application/json' \
            -H "API-Key: ${SECRET_NEWRELIC_API_KEY}" \
            --data-binary '{"query":"mutation { dashboardCreateSnapshotUrl(guid: \"'${subDashboard}'\") } ", "variables":""}'
        )

        dashboardUrl=$( \
            echo "${dashboardUrlResponse}" \
            | jq -r '.data.dashboardCreateSnapshotUrl' \
            | sed 's/format=PDF/format=PNG/' \
        )

        # Download and show
        wget -q "${dashboardUrl}" -O - | imgcat -R
    done
}

function recs-reviewers-glue-job-status {
    aws glue get-job-runs --job-name coalesce-daily-recommendations \
        | jq -r '["Completed", "State"], (.JobRuns | sort_by(.CompletedOn) | .[] | [.CompletedOn, .JobRunState]) | @csv' \
        | strip-quotes \
        | tabulate-by-comma \
        | highlight green SUCCEEDED \
        | highlight red FAILED
}

# SonarQube                                                                 {{{1
# ==============================================================================

function sonarqube-run() {
    if [[ $# -ne 1 ]] ; then
        echo "Usage: sonarqube-run TOKEN"
        echo "  Token can be retrieved from recs-secrets"
    else
        local sonarToken=$1

        local sonarServer="https://sq.prod.tio.elsevier.systems"
        local sonarScannerHome=$(full-path "$(which sonar-scanner | xargs greadlink -f | xargs dirname)/..")
        local sonarOpts="-Dsonar.host.url=\"${sonarServer}\" -DsonarScanner.home=\"${sonarScannerHome}\" -Dsonar.login=\"${sonarToken}\""

        echo "NOTE: Ensure you have first generated coverage with 'sbt clean coverage test coverageReport'"
        echo "Using sonar-scanner at ${sonarScannerHome}"
        SONAR_SCANNER_HOME="${sonarScannerHome}" sbt -Dsonar.host.url="${sonarServer}" -Dsonar.login="${sonarToken}" sonarScan
    fi
}

# Conda                                                                     {{{1
# ==============================================================================

function conda-insinuate() {
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/usr/local/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
            . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
        else
            export PATH="/usr/local/Caskroom/miniconda/base/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
}

# Newsflo AWS                                                               {{{1
# ==============================================================================

function sshx-tagged-aws-machines() {
    if [[ $# -ne 3 ]] ; then
        echo 'Usage: sshx-tagged-aws-machines TAG'
        return 1
    fi

    declare tag=$1

    echo 'Finding machines'
    machines=($(aws ec2 describe-instances | jq --raw-output '.Reservations[].Instances[]? | select(.State.Name=="running") | select(.Tags[] | select((.Key=="Name") and (.Value=="'$tag'"))) | .NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress'))

    echo "Opening SSH to $machines[*]"
    i2cssh $machines[*]
}

function aws-instance-info() {
    local tag=$1

    aws ec2 describe-instances | jq --raw-output '.Reservations[].Instances[]? | select(.Tags[].Value=="'$tag'") | select(.State.Name=="running")'
}
compdef _aws-tag aws-instance-info

# List the values of tagged AWS instances
function aws-tag-values() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: aws-tag-values PROFILE REGION KEY'
        return 1
    fi

    local key=$1

    aws ec2 describe-instances | jq --raw-output '.Reservations[].Instances[].Tags[]? | select(.Key=="'$key'") | .Value' | sort | uniq
}
compdef _aws-tag aws-tag-values

# List the IPs for tagged AWS instances
function aws-instance-ips() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: aws-instance-ips TAG'
        return 1
    fi

    local tag=$1

    aws ec2 describe-instances | jq --raw-output '.Reservations[].Instances[] | select(.Tags[]?.Value=="'$tag'") | select(.State.Name=="running") | .PrivateIpAddress' | sort | uniq
}
compdef _aws-tag aws-instance-ips

# List the IPs for all AWS instances
function aws-all-instance-ips() {
    local jqScript
    read-heredoc jqScript <<HEREDOC
    [.Reservations[].Instances[]?
        | select(.State.Name=="running")
        | {
             name:         (.Tags | map({key: .Key, value: .Value}) | from_entries | .Name // "-"),
             ipAddress:    .PrivateIpAddress,
             instanceId:   .InstanceId,
             instanceType: .InstanceType,
             imageId:      .ImageId,
             launchTime:   .LaunchTime,
             monitoring:   .Monitoring.State
          }
    ]
    | sort_by(.name)
HEREDOC

    aws ec2 describe-instances \
        | jq -r "${jqScript}" \
        | json-to-csv \
        | strip-quotes \
        | tabulate-by-comma
}

# For each region in AWS, execute the specified function
function aws-for-all-regions() {
    local originalRegion=${AWS_REGION}

    local regions=$(aws ec2 describe-regions | jq -r '.Regions[].RegionName')

    while read -r region; do
        echo "$region"
        export AWS_REGION=${region}
        "$@"
        echo
    done < <(echo ${regions})

    export AWS_REGION=${originalRegion}
}

# List the IPs for all AWS instances in all regions
function aws-all-instance-ips-all-regions() {

    list-instances() {
        aws-all-instance-ips 2>/dev/null
    }

    aws-for-all-regions list-instances
}

# List the DynamoDB tables in all regions
function aws-all-regions-dynamodb-tables() {

    list-tables() {
        aws dynamodb list-tables | jq -r '.TableNames[]'
    }

    aws-for-all-regions list-tables
}


# List AWS instance limits
function aws-ec2-instance-limits() {
    aws service-quotas list-service-quotas --service-code ec2 | jq --raw-output '(.Quotas[] | ([.QuotaName, .Value])) | @csv' | column -t -s "," | sed 's/\"//g'
}

function active-directory-service-user-info() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: active-directory-service-user-info USERNAME"
        return 1
    fi
    dscl "/Active Directory/SCIENCE/All Domains" read "/Users/${1}"
    echo "For more detailed information open the 'Directory Utility' app"
}

function recs-build-and-publish-jar() {
    sbt-no-test clean assembly

    local assembly=$(find target -type f -name *-assembly-*.jar)
    local appsPath=s3://com-elsevier-recs-live-experiments/stuw-hacked-apps

    if [[ $assembly =~ ".*/(.*)-assembly-.*" ]]
    then
        local prefix="${BASH_REMATCH[2]}"
        local timestamp=$(date +"%Y%m%d-%H%M")
        local name="${prefix}-assembly-hacked-app-${timestamp}.jar"

        aws-recs-prod
        aws s3 cp "${assembly}" "${appsPath}/${name}"
    else
        echo "Assembly not found"
    fi
}

# Reviewer Recommender                                                      {{{1
# ==============================================================================

function rr-quality-metrics() {
    aws-recs-login live > /dev/null

    latestRun=$(aws s3 ls s3://com-elsevier-recs-live-reviewers/quality-metrics/metrics/demographic-parities/gender/selection-rates/ \
        | tail -n 1 \
        | gsed -r 's/.* PRE (.+)\/$/\1/')

    runId=${latestRun}

    echo ${runId}
    echo

    metrics=(
        demographic-parities
        equal-opportunity-statistics
    )

    characteristics=(
        gender
        geographicallocation
        seniority
    )

    subMetrics=(
        selection-rate-parities
        selection-rates
    )

    for characteristic in "${characteristics[@]}"
    do
        for metric in "${metrics[@]}"
        do
            for subMetric in "${subMetrics[@]}"
            do
                echo "${metric}/${characteristic}/${subMetric}"
                echo
                jsonFile=$(aws s3 ls s3://com-elsevier-recs-live-reviewers/quality-metrics/metrics/${metric}/${characteristic}/${subMetric}/${runId}/data/ \
                    | grep 'part-' \
                    | gsed -r 's/.* (part-.+\.json)$/\1/g')

                if [[ "${subMetric}" = 'selection-rates' ]]; then
                    aws s3 cp s3://com-elsevier-recs-live-reviewers/quality-metrics/metrics/${metric}/${characteristic}/${subMetric}/${runId}/data/${jsonFile} - \
                        | jq -s '.' \
                        | json-to-csv \
                        | strip-quotes \
                        | tabulate-by-comma
                else
                    aws s3 cp s3://com-elsevier-recs-live-reviewers/quality-metrics/metrics/${metric}/${characteristic}/${subMetric}/${runId}/data/${jsonFile} - \
                        | jq '[.label, .selectionRateA.model, .selectionRateParity]' \
                        | jq -s '.' \
                        | json-to-csv \
                        | tail -n +2 \
                        | strip-quotes \
                        | tabulate-by-comma
                fi
                echo
            done
        done
    done
}

function rr-lambda-performance() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-lambda-performance (dev|staging|live)"
        return 1
    fi

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    # Pull out manuscript ID, stage, and duration from the logs
    # Ignore JDBCService initialisation because there is no manuscript ID associated to group by
    local timingData=$(
        awslogs get --no-group --no-stream --timestamp -s "5m" /aws/lambda/recs-reviewers-recommender-lambda-${recsEnv} \
            | grep -e 'Instrumentation\$:' \
            | grep -v 'JDBCService#initialise' \
            | gsed -r 's/^.* \[(.+)\] Instrumentation\$:.+ (.+) - ([0-9]+) ms$/\1 \2 \3/' \
            | (echo 'ManuscriptId' 'Stage' 'Duration' && cat)
    )

    # Sum stages for each manuscript, so multiple invocations of the same operation are added together
    local totalPerStage=$(
        echo ${timingData} \
            | datamash --sort --field-separator=' ' --header-in -g ManuscriptId,Stage sum Duration \
            | (echo 'ManuscriptId' 'Stage' 'TotalDuration' && cat)
    )

    # Display min, mean, and max for each stage
    local statsPerStage=$(
        echo ${totalPerStage} \
            | datamash --sort --field-separator=' ' --header-in --round=1 -g Stage min TotalDuration mean TotalDuration max TotalDuration \
            | (echo 'Stage' 'Min' 'Mean' 'Max' && cat)
    )
    echo ${statsPerStage} | tabulate-by-space

    # Display min, mean, and max total time
    echo
    echo ${statsPerStage} \
        | datamash --sort --field-separator=' ' --header-in --round=1 sum Min sum Mean sum Max \
        | (echo 'TotalMin' 'TotalMean' 'TotalMax' && cat) \
        | tabulate-by-space

    # Display ElasticSearch configuration for reference
    echo
    aws es describe-elasticsearch-domain --domain-name "recs-reviewers" \
        | jq -r '["Instance", "InstanceCount", "Master", "MasterCount", "VolumeType", "IOPs"], (.DomainStatus | [(.ElasticsearchClusterConfig | .InstanceType, .InstanceCount, .DedicatedMasterType, .DedicatedMasterCount), (.EBSOptions | .VolumeType, .Iops)]) | @tsv' \
        | tabulate-by-tab
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-lambda-performance

function rr-error-queue-depth-live() {
    aws-recs-login live > /dev/null

    aws sqs get-queue-attributes \
        --queue-url https://sqs.us-east-1.amazonaws.com/589287149623/recs_rev_recommender_lambda_errors_dlq \
        --attribute-names All \
        | jq -r '.Attributes.ApproximateNumberOfMessages'
}

function rr-lambda-iterator-age() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-lambda-iterator-age (dev|staging|live)"
        return 1
    fi

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    echo 'Iterator age at' $(date --iso-8601=seconds)
    echo
    aws cloudwatch get-metric-statistics \
        --namespace 'AWS/Lambda' \
        --dimensions Name=FunctionName,Value=recs-reviewers-recommender-lambda-${recsEnv} \
        --metric-name 'IteratorAge' \
        --start-time $(date --iso-8601=seconds --date='45 minutes ago') \
        --end-time   $(date --iso-8601=seconds) \
        --period 300 \
        --statistics Maximum \
        | jq -r '["Time", "Seconds", "Minutes", "Hours"], (.Datapoints | sort_by(.Timestamp) | .[] | [.Timestamp, .Maximum/1000, .Maximum/(60 * 1000), .Maximum/(60 * 60 * 1000)]) | @tsv' \
        | tabulate-by-tab
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-lambda-iterator-age

function rr-data-pump-lambda-submitted-manuscripts() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-data-pump-lambda-submitted-manuscripts (dev|staging|live)"
        return 1
    fi

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    local KINESIS_STREAM_NAME="recs-reviewers-submitted-manuscripts-stream-${recsEnv}"

    local SHARD_ITERATOR=$(aws kinesis get-shard-iterator \
        --shard-id shardId-000000000000 \
        --shard-iterator-type TRIM_HORIZON \
        --stream-name $KINESIS_STREAM_NAME \
        --query 'ShardIterator')

    aws kinesis get-records --shard-iterator $SHARD_ITERATOR \
        | jq -r '.Records[] | .Data | @base64d' \
        | jq -r '.'
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-data-pump-lambda-submitted-manuscripts

function rr-recent-recommendations() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-recent-recommendations (dev|staging|live)"
        return 1
    fi

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    awslogs get --no-group --no-stream --timestamp "/aws/lambda/recs-reviewers-recommender-lambda-${recsEnv}" -f 'ManuscriptService' \
        | gsed -r 's/.* Manuscript id: (.+)$/\1/g' \
        | grep -e '^[^ ]\+$'
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-recent-recommendations

function rr-lambda-invocations() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-lambda-invocations (dev|staging|live)"
        return 1
    fi

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    lambdas=(
        recs-rev-reviewers-data-pump-lambda-${recsEnv}
        recs-rev-manuscripts-data-pump-lambda-${recsEnv}
        recs-reviewers-recommender-lambda-${recsEnv}
    )

    for lambda in "${lambdas[@]}"
    do
        echo "${lambda}"
        aws cloudwatch get-metric-statistics \
            --namespace 'AWS/Lambda' \
            --dimensions Name=FunctionName,Value="${lambda}" \
            --metric-name 'Invocations' \
            --start-time $(date --iso-8601=seconds --date='7 days ago') \
            --end-time   $(date --iso-8601=seconds) \
            --period $(calc '60 * 60 * 24') \
            --statistics Sum \
            | jq -r '["Time", "Total"], (.Datapoints | sort_by(.Timestamp) | .[] | [.Timestamp, .Sum]) | @csv' \
            | gsed 's/"//g' \
            | gsed "s/,,/,-,/g" \
            | column -t -s ','
        echo
    done
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-lambda-invocations

function rr-lambda-backlog() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: rr-lambda-backlog (dev|staging|live)"
        return 1
    fi

    local _lambda-invocations() {
        local lambda="${1}"

        aws cloudwatch get-metric-statistics \
            --namespace 'AWS/Lambda' \
            --dimensions Name=FunctionName,Value="${lambda}" \
            --metric-name 'Invocations' \
            --start-time $(date --iso-8601=seconds --date='3 days ago') \
            --end-time   $(date --iso-8601=seconds) \
            --period $(calc '60 * 60') \
            --statistics Sum \
            | jq -r '["Time", "Total"], (.Datapoints | sort_by(.Timestamp) | .[] | [.Timestamp, .Sum]) | @csv'
    }

    local pumpDataFilename=.data-pump-invocations.csv
    local lambdaDataFilename=.lambda-invocations.csv
    local backlogDataFilename=backlog.txt
    local backlogImageFilename=backlog.png

    local recsEnv="${1}"
    aws-recs-login $recsEnv > /dev/null

    _lambda-invocations recs-rev-manuscripts-data-pump-lambda-${recsEnv} > ${pumpDataFilename}
    _lambda-invocations recs-reviewers-recommender-lambda-${recsEnv}     > ${lambdaDataFilename}

    local joinScript
    read-heredoc joinScript <<HEREDOC
        SELECT
            dp.Time AS time,
            dp.Total AS pump_count,
            l.Total AS lambda_count
        FROM ${pumpDataFilename} dp INNER JOIN ${lambdaDataFilename} l
        ON dp.Time = l.Time
HEREDOC

    local metricsScript
    read-heredoc metricsScript <<HEREDOC
        SELECT
            time,
            pump_count,
            sum(pump_count) over (ORDER BY time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as pump_total,
            lambda_count,
            sum(lambda_count) over (ORDER BY time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as lambda_total
        FROM -
HEREDOC

    q -d ',' -H -O "${joinScript}" \
        | q -d ',' -H -O "${metricsScript}" \
        | q -d ',' -H -O "SELECT time, pump_total, lambda_total, pump_total - lambda_total as backlog_size FROM -" \
        | tabulate-by-comma \
        > backlog.txt

    local gnuplotScript
    read-heredoc gnuplotScript <<HEREDOC
        set style data line
        set xdata time
        set timefmt "%Y-%m-%dT%H:%M:%S+00:00"
        set terminal png size 800,600 enhanced
        set output 'backlog.png'
        plot \
            "backlog.txt" using 1:2 title "Pump total"   linewidth 3, \
            "backlog.txt" using 1:3 title "Lambda total" linewidth 3, \
            "backlog.txt" using 1:4 title "Backlog"      linewidth 3
HEREDOC

    echo ${gnuplotScript} | gnuplot
    imgcat backlog.png

    rm ${pumpDataFilename}
    rm ${lambdaDataFilename}
    rm ${backlogDataFilename}
    rm ${backlogImageFilename}
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    rr-lambda-backlog

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
