# ============================================================================
# prompt.zsh
# v0.3.0
# ============================================================================

declare -A PROMPT_COLOR
PROMPT_COLOR[host]="1;32"
PROMPT_COLOR[dir]="1;34"
PROMPT_COLOR[ptr]="1"
PROMPT_COLOR[error]="1;31"
PROMPT_COLOR[bgjobs]="1;2;37"
PROMPT_COLOR[branch]="1;35"

declare -A PROMPT_CHAR
(( $UID == 0 )) && PROMPT_CHAR[ptr]="#" || PROMPT_CHAR[ptr]=">"
PROMPT_CHAR[branch]=$'\u2387 '

precmd_functions+=(__prompt)

__prompt() {
  # pipestatus will be overwritten after the first command
  __pipestatus="$pipestatus"
  [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
    && __prompt_error_occurred=0 \
    || __prompt_error_occurred=1

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
  local color
  (( $__prompt_error_occurred )) \
    && color=$PROMPT_COLOR[error] \
    || color=$PROMPT_COLOR[ptr]

  REPLY=$'%{\e['$color'm%}'$PROMPT_CHAR[ptr]$'%{\e[0m%}'
}

__prompt_error() {
  (( $__prompt_error_occurred )) \
    && REPLY=$'%{\e['$PROMPT_COLOR[error]'m%}['$__pipestatus$']%{\e[0m%}' \
    || REPLY=""
}

__prompt_bgjobs() {
  local -i num_jobs=${#jobtexts[@]}
  (( num_jobs > 0 )) \
    && REPLY=$'%{\e['$PROMPT_COLOR[bgjobs]'m%}*'$num_jobs$'%{\e[0m%}' \
    || REPLY=""
}

__prompt_branch() {
  local head branch color char

  __prompt_git_head "$PWD"; head="$REPLY"

  [[ -z "$head" ]] && REPLY="" && return
  __prompt_git_branch "$head"; branch="$REPLY"

  [[ -z "$branch" ]] && REPLY="" && return

  color=$PROMPT_COLOR[branch]
  char=$PROMPT_CHAR[branch]
  REPLY=$'%{\e['$color'm%}'$char$branch$'%{\e[0m%}'
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
