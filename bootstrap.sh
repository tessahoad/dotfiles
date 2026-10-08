#!/bin/zsh

# vim:fdm=marker

# Options                                                                   {{{1
# ==============================================================================

setopt EXTENDED_GLOB

# Constants                                                                 {{{1
# ==============================================================================

# Files to link to in $HOME
FILES=(
    "git/.gitconfig"
    "git/.githooks"
    "tmux/.tmux.conf"
    "zsh/.zshenv"
    "zsh/.zshenv.secret"
    "zsh/.zshrc"
    "q/.qrc"
)

# Directories to link to in $HOME/.config
CONFIG_DIRS=(
    "tmuxinator/tmuxinator"
)

# Scripts to link to in $HOME/bin, which is already on $PATH
BIN_DIRS=(
    "tmuxinator/bin"
)

# Files to link to in $HOME/.copilot
COPILOT_DIRS=(
    "copilot/hooks"
    "copilot/copilot-instructions.md"
)

COPILOT_SKILLS=(
    "copilot/skills/codegraph-exploration"
)

# Files to link to in $HOME/.claude
CLAUDE_DIRS=(
    "claude/settings.json"
    "claude/CLAUDE.md"
    "claude/claude-notify.sh"
    "claude/agents"
)

CLAUDE_SKILLS=(
    "claude/skills/codegraph-exploration"
)

CODEX_DIRS=(
    "codex/hooks.json"
    "codex/AGENTS.md"
)

CODEX_SKILLS=(
    "codex/skills/codegraph-exploration"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COLOR='\033[0m'
CLEAR_LINE='\r\033[K'

# Functions                                                                 {{{1
# ==============================================================================

# Display success message
# msg_success "Something succeeded"
function msg_success() {
    declare msg=$1
    printf "${CLEAR_LINE}${GREEN}✔ ${msg}${NO_COLOR}\n"
}

# Display a warning message
# msg_error "An error occurred"
function msg_error() {
    declare msg=$1
    printf "${CLEAR_LINE}${RED}✘ ${msg}${NO_COLOR}\n"
}

function relative-path() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

function create-link() {
    declare targetDir=$1 file=$2

    local localPath=$(relative-path $file)
    local homePath="$targetDir/$(basename $localPath)"

    mkdir -p "$targetDir"

    if [[ -L "$homePath" ]]; then
        local linkTarget=$(readlink -- "$homePath")
        if [ $linkTarget = $localPath ]; then
            msg_success "Exists:  $homePath -> $localPath"
        else
            msg_error "Error:   $homePath -> $linkTarget exists (should point to $localPath)"
        fi
    elif [[ -e "$homePath" ]]; then
        mv "$homePath" "$homePath.bak"
        ln -s "$localPath" "$homePath"
        msg_success "Created: $homePath -> $localPath (existing file moved to $homePath.bak)"
    else
        ln -s "$localPath" "$homePath"
        msg_success "Created: $homePath -> $localPath"
    fi
}

function create-links-for-files() {
    local targetDir=$1
    shift
    local files=($@)

    for file in "${files[@]}"
    do
        if [[ -e $file ]]; then
            create-link $targetDir $file
        else
            msg_error "Error:   $file not found"
        fi
    done
}

function create-links-for-files-at-path() {
    local targetDir=$1
    local sourceDir=$2

    for file in $(find "${sourceDir}" -type f)
    do
        if [[ -e $file ]]; then
            create-link $targetDir $file
        else
            msg_error "Error:   $file not found"
        fi
    done
}

# Installation                                                              {{{1
# ==============================================================================

create-links-for-files $HOME          "$FILES[@]"

mkdir -p $HOME/.config/
create-links-for-files $HOME/.config  "$CONFIG_DIRS[@]"

create-links-for-files $HOME/.copilot "$COPILOT_DIRS[@]"
create-links-for-files $HOME/.claude  "$CLAUDE_DIRS[@]"
create-links-for-files $HOME/.codex   "$CODEX_DIRS[@]"

mkdir -p "$HOME/.copilot/skills" "$HOME/.claude/skills" "$HOME/.codex/skills"
create-links-for-files "$HOME/.copilot/skills" "$COPILOT_SKILLS[@]"
create-links-for-files "$HOME/.claude/skills" "$CLAUDE_SKILLS[@]"
create-links-for-files "$HOME/.codex/skills" "$CODEX_SKILLS[@]"

mkdir -p $HOME/bin
for binDir in "$BIN_DIRS[@]"
do
    create-links-for-files-at-path $HOME/bin $binDir
done


create-links-for-files-at-path ~/Developer/tessahoad     git/home-config
create-links-for-files-at-path ~/Developer/recommenders  git/elsevier-config
create-links-for-files-at-path ~/Developer/submissions   git/elsevier-config
