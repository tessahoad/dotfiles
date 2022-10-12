# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

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

# Other useful stuff
alias reload-zsh-config="exec zsh"                                          # Reload Zsh config
alias zsh-startup='time  zsh -i -c exit'                                    # Display Zsh start-up time
alias display-colours='msgcat --color=test'                                 # Display terminal colors
alias list-ports='netstat -anv'                                             # List active ports

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

function install-java-certificate() {
    if [[ $# -ne 1 ]] ; then
        echo 'Usage: install-java-certificate FILE'
        return 1
    fi

    local certificate=$1

    local keystores=$(find /Library -name cacerts | grep JavaVirtualMachines)
    while IFS= read -r keystore; do
        echo
        echo sudo keytool -importcert -file \
            "${certificate}" -keystore "${keystore}" -alias Zscalar

        # keytool -list -keystore "${keystore}" | grep -i zscalar
    done <<< "${keystores}"
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
    local dirs=$(find . -type d -maxdepth 1)

    echo "$dirs" \
        | env_parallel --env "$1" -j20 \
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

        echo "${branch},${sync},${dirty},${repo}"
    }

    git-for-each-repo display-status | column -t -s ','
}

# Java                              {{{2
# ======================================

alias get-java-locations="/usr/libexec/java_home -V"
alias use-java-8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`"

# AWS authentication                {{{2
# ======================================

alias aws-which="env | grep AWS | sort"
alias aws-clear-variables="for i in \$(aws-which | cut -d= -f1,1 | paste -); do unset \$i; done"
alias aws-who-am-i="aws sts get-caller-identity"

function aws-switch-role() {
    declare roleARN=$1 profile=$2

    export username=hoadt@science.regn.net
    LOGIN_OUTPUT="$(aws-adfs login --adfs-host federation.reedelsevier.com --region us-east-1 --session-duration 14400 --role-arn $roleARN --env --profile $profile --printenv | grep export)"
    AWS_ENV="$(echo $LOGIN_OUTPUT | grep export)"
    eval $AWS_ENV
    export AWS_REGION=us-east-1
    aws-which
}

function aws-developer-role() {
    declare accountId=$1 role=$2 profile=$3
    aws-switch-role "arn:aws:iam::${accountId}:role/${role}" "${profile}"
}

alias aws-recs-dev-developer="aws-developer-role $SECRET_ACC_RECS_DEV ADFS-Developer aws-rap-recommendersdev"
alias aws-recs-prod-developer="aws-developer-role $SECRET_ACC_RECS_PROD ADFS-Developer aws-rap-recommendersprod"
alias aws-recs-prod-enterprise-admin="aws-developer-role $SECRET_ACC_RECS_PROD ADFS-EnterpriseAdmin aws-rap-recommendersprod"

function aws-recs-login() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: aws-recs-login (dev|staging|live)"
    else
        local recsEnv=$1

        case "${recsEnv}" in
            dev*)
                aws-recs-dev
            ;;

            staging*)
                aws-recs-dev
            ;;

            live*)
                aws-recs-prod
            ;;

            *)
                echo "ERROR: Unrecognised environment ${recsEnv}"
                return -1
            ;;
        esac
    fi
}
compdef "_arguments \
    '1:environment arg:(dev staging live)'" \
    aws-recs-login

# AWS helper functions              {{{2
# ======================================

# AWS CLI commands pointing at localstack
alias aws-localstack='aws --endpoint-url=http://localhost:4566'

# List ECR images
function aws-ecr-images() {
    local repos=$(aws ecr describe-repositories \
        | jq -r ".repositories[].repositoryName" \
        | sort)

    while IFS= read -r repo; do
        echo $repo
        AWS_PAGER="" aws ecr describe-images --repository-name "${repo}" \
            | jq -r '.imageDetails[] | select(has("imageTags")) | .imageTags[] | select(test( "^\\d+\\.\\d+\\.\\d+$" ))' \
            | sort
        echo
    done <<< "$repos"
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

# List EMR statuses
function aws-emr-status() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: aws-recs-login (dev|staging|live)"
    else
        local clusterId=$1
        aws emr list-steps \
            --cluster-id "${clusterId}" \
            | jq -r '.Steps[] | [.Name, .Status.State, .Status.Timeline.StartDateTime, .Status.Timeline.EndDateTime] | @csv' \
            | column -t -s ',' \
            | sed 's/"//g'

        aws emr describe-cluster \
            --cluster-id "${clusterId}" \
            | jq -r ".Cluster | (.LogUri + .Id)" \
            | sed 's/s3n:/s3:/'
    fi
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

