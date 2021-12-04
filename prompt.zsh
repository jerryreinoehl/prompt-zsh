# ============================================================================
# prompt.zsh
# v0.4.0
# ============================================================================

declare -A PSCFG
PSCFG[host.color]="1;32"
PSCFG[dir.color]="1;34"
PSCFG[prompt.color]="1"
PSCFG[error.color]="1;31"
PSCFG[jobs.color]="1;2;37"
PSCFG[branch.color]="1;35"

PSCFG[error.fmt]="[%s]"
PSCFG[jobs.fmt]="*%s"
PSCFG[branch.fmt]=$'\u2387 %s'

(( $UID == 0 )) && PSCFG[prompt.fmt]="#" || PSCFG[prompt.fmt]=">"
PSCFG[prompt.vicmd_fmt]=":"

zle -N prompt-ps1 __prompt_ps1
zle -N prompt-rps1 __prompt_rps1
zle -N zle-keymap-select

zle-keymap-select() {
  local save_prompt="$PSCFG[prompt.fmt]"

  [[ "$KEYMAP" == "vicmd" ]] && PSCFG[prompt.fmt]="$PSCFG[prompt.vicmd_fmt]"
  zle prompt-ps1
  zle reset-prompt
  PSCFG[prompt.fmt]="$save_prompt"
}

precmd_functions+=(__prompt)

__prompt() {
  # pipestatus will be overwritten after the first command
  __prompt_pipestatus="$pipestatus"
  [[ "$__prompt_pipestatus" =~ ^0( 0)*$ ]] \
    && __prompt_error_occurred=0 \
    || __prompt_error_occurred=1

  __prompt_ps1
  __prompt_rps1
}

__prompt_ps1() {
  local prmpt REPLY

  __prompt_prompt; prmpt="$REPLY"

  PS1=$'%{\e['$PSCFG[host.color]$'m%}%n@%m%{\e[0m%}'
  PS1+=$' %{\e['$PSCFG[dir.color]$'m%}%1~%{\e[0m%}'
  PS1+=" $prmpt "
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

__prompt_prompt() {
  local color

  (( __prompt_error_occurred )) \
    && color=$PSCFG[error.color] \
    || color=$PSCFG[prompt.color]

  REPLY=$'%{\e['$color'm%}'$PSCFG[prompt.fmt]$'%{\e[0m%}'
}

__prompt_error() {
  (( __prompt_error_occurred )) \
    && __prompt_fmt_str "$PSCFG[error.color]" "$PSCFG[error.fmt]" \
                        "$__prompt_pipestatus" \
    || REPLY=""
}

__prompt_jobs() {
  local -i num_jobs=${#jobtexts[@]}

  (( num_jobs > 0 )) \
    && __prompt_fmt_str "$PSCFG[jobs.color]" "$PSCFG[jobs.fmt]" "$num_jobs" \
    || REPLY=""
}

__prompt_branch() {
  local branch color char

  __prompt_git_branch; branch="$REPLY"

  [[ -z "$branch" ]] && REPLY="" && return

  __prompt_fmt_str "$PSCFG[branch.color]" "$PSCFG[branch.fmt]" "$branch"
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

__prompt_fmt_str() {
  local color="$1" fmt="$2" str="$3"

  REPLY=$'%{\e['$color'm%}'${fmt//\%s/$str}$'%{\e[0m%}'
}
