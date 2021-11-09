# ============================================================================
# prompt.zsh
# v0.4.0
# ============================================================================

declare -A PSCFG
PSCFG[host.color]="1;32"
PSCFG[dir.color]="1;34"
PSCFG[ptr.color]="1"
PSCFG[error.color]="1;31"
PSCFG[jobs.color]="1;2;37"
PSCFG[branch.color]="1;35"

(( $UID == 0 )) && PSCFG[ptr]="#" || PSCFG[ptr]=">"
PSCFG[branch]=$'\u2387 '

zle -N prompt-ps1 __prompt_ps1
zle -N prompt-rps1 __prompt_rps1
zle -N zle-keymap-select

zle-keymap-select() {
  local save_ptr="$PSCFG[ptr]"

  [[ "$KEYMAP" == "vicmd" ]] && PSCFG[ptr]=":"
  zle prompt-ps1
  zle reset-prompt
  PSCFG[ptr]="$save_ptr"
}

precmd_functions+=(__prompt)

__prompt() {
  # pipestatus will be overwritten after the first command
  __pipestatus="$pipestatus"
  [[ "$__pipestatus" =~ ^0( 0)*$ ]] \
    && __prompt_error_occurred=0 \
    || __prompt_error_occurred=1

  __prompt_ps1
  __prompt_rps1
}

__prompt_ps1() {
  local ptr REPLY

  __prompt_ptr; ptr="$REPLY"

  PS1=$'%{\e['$PSCFG[host.color]$'m%}%n@%m%{\e[0m%}'
  PS1+=$' %{\e['$PSCFG[dir.color]$'m%}%1~%{\e[0m%}'
  PS1+=" $ptr "
}

__prompt_rps1() {
  local branch error bgjobs REPLY

  __prompt_error; error="$REPLY"
  __prompt_jobs; bgjobs="$REPLY"
  __prompt_branch; branch="$REPLY"

  RPS1=""
  [[ -n "$error" ]] && RPS1+="$error"
  [[ -n "$bgjobs" ]] && RPS1+=" $bgjobs"
  [[ -n "$branch" ]] && RPS1+=" $branch"
}

__prompt_ptr() {
  local color

  (( __prompt_error_occurred )) \
    && color=$PSCFG[error.color] \
    || color=$PSCFG[ptr.color]

  REPLY=$'%{\e['$color'm%}'$PSCFG[ptr]$'%{\e[0m%}'
}

__prompt_error() {
  (( __prompt_error_occurred )) \
    && REPLY=$'%{\e['$PSCFG[error.color]'m%}['$__pipestatus$']%{\e[0m%}' \
    || REPLY=""
}

__prompt_jobs() {
  local -i num_jobs=${#jobtexts[@]}

  (( num_jobs > 0 )) \
    && REPLY=$'%{\e['$PSCFG[jobs.color]'m%}*'$num_jobs$'%{\e[0m%}' \
    || REPLY=""
}

__prompt_branch() {
  local branch color char

  __prompt_git_branch; branch="$REPLY"

  [[ -z "$branch" ]] && REPLY="" && return

  color=$PSCFG[branch.color]
  char=$PSCFG[branch]
  REPLY=$'%{\e['$color'm%}'$char$branch$'%{\e[0m%}'
}

__prompt_git_branch() {
  local head ref

  __prompt_git_head "$PWD"; head="$REPLY"
  [[ -z "$head" ]] && REPLY="" && return

  read ref < "$head"
  [[ "$ref" =~ ^ref: ]] && REPLY="${ref##*/}" || REPLY="${ref:0:6}"
}

__prompt_git_head() {
  local dir="$1"
  REPLY=""

  while [[ -n "$dir" ]]; do
    [[ -r "$dir/.git/HEAD" ]] && REPLY="$dir/.git/HEAD" && return
    dir="${dir%/*}"
  done
}
