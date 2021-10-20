precmd() {
    # pipestatus will be overwritten after the first command
    __pipestatus="$pipestatus"
    __prompt
}

__prompt() {
    local ptr branch error bgjobs REPLY

    __prompt_pointer; ptr="$REPLY"
    __prompt_error; error="$REPLY"
    __prompt_bgjobs; bgjobs="$REPLY"
    __prompt_branch; branch="$REPLY"

    PS1="%B%F{green}%n@%m%f %F{blue}%1~%f%b $ptr "

    RPS1=""
    [[ -n "$error" ]] && RPS1+="$error"
    [[ -n "$bgjobs" ]] && RPS1+=" $bgjobs"
    [[ -n "$branch" ]] && RPS1+=" $branch"
}

__prompt_pointer() {
    [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
        && REPLY="%B%(!.#.>)%b" \
        || REPLY="%B%F{red}%(!.#.>)%f%b"
}

__prompt_error() {
    [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
        && REPLY="" \
        || REPLY="%B%F{red}[$__pipestatus]%f%b"
}

__prompt_bgjobs() {
    local -i num_jobs=${#jobtexts[@]}
    (( num_jobs > 0 )) \
        && REPLY=$'%{\e[1;2;37m%}*'$num_jobs$'%{\e[0m%}' \
        || REPLY=""
}

__prompt_branch() {
    local head branch

    __prompt_git_head "$PWD"; head="$REPLY"

    [[ -z "$head" ]] && REPLY="" && return
    __prompt_git_branch "$head"; branch="$REPLY"

    [[ -z "$branch" ]] && REPLY="" && return
    REPLY=$'%B%F{magenta}\u2387 '$branch'%f%b'
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
