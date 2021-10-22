# ============================================================================
# prompt.zsh
# v0.2.0
# ============================================================================

declare -A PROMPT_COLOR
PROMPT_COLOR[host]="1;32"
PROMPT_COLOR[dir]="1;34"
PROMPT_COLOR[ptr]="1"
PROMPT_COLOR[error]="1;31"
PROMPT_COLOR[bgjobs]="1;2;37"
PROMPT_COLOR[branch]="1;35"

precmd_functions+=(__prompt)

__prompt() {
    # pipestatus will be overwritten after the first command
    __pipestatus="$pipestatus"

    local ptr branch error bgjobs REPLY

    __prompt_pointer; ptr="$REPLY"
    __prompt_error; error="$REPLY"
    __prompt_bgjobs; bgjobs="$REPLY"
    __prompt_branch; branch="$REPLY"

    PS1=$'%{\e['$PROMPT_COLOR[host]$'m%}%n@%m%{\e[0m%}'
    PS1+=$' %{\e['$PROMPT_COLOR[dir]$'m%}%1~%{\e[0m%}'
    PS1+=" $ptr "

    RPS1=""
    [[ -n "$error" ]] && RPS1+="$error"
    [[ -n "$bgjobs" ]] && RPS1+=" $bgjobs"
    [[ -n "$branch" ]] && RPS1+=" $branch"
}

__prompt_pointer() {
    [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
        && REPLY=$'%{\e['$PROMPT_COLOR[ptr]$'m%}%(!.#.>)%{\e[0m%}' \
        || REPLY=$'%{\e['$PROMPT_COLOR[error]$'m%}%(!.#.>)%{\e[0m%}'
}

__prompt_error() {
    [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
        && REPLY="" \
        || REPLY=$'%{\e['$PROMPT_COLOR[error]'m%}['$__pipestatus$']%{\e[0m%}'
}

__prompt_bgjobs() {
    local -i num_jobs=${#jobtexts[@]}
    (( num_jobs > 0 )) \
        && REPLY=$'%{\e['$PROMPT_COLOR[bgjobs]'m%}*'$num_jobs$'%{\e[0m%}' \
        || REPLY=""
}

__prompt_branch() {
    local head branch

    __prompt_git_head "$PWD"; head="$REPLY"

    [[ -z "$head" ]] && REPLY="" && return
    __prompt_git_branch "$head"; branch="$REPLY"

    [[ -z "$branch" ]] && REPLY="" && return
    REPLY=$'%{\e['$PROMPT_COLOR[branch]$'m%}\u2387 '$branch$'%{\e[0m%}'
}

__prompt_git_head() {
    local dir="$1"
    REPLY=""

    while [[ -n "$dir" ]]; do
        [[ -r "$dir/.git/HEAD" ]] && REPLY="$dir/.git/HEAD" && return
        dir="${dir%/*}"
    done
}

__prompt_git_branch() {
    local head="$1" ref

    read ref < "$head"
    [[ "$ref" =~ ^ref: ]] && REPLY="${ref##*/}" || REPLY="${ref:0:6}"
}
