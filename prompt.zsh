# ============================================================================
# prompt.zsh
# v2.0.0
# ============================================================================

declare -A PSCFG
PSCFG[version]="2.0.0"

PSCFG[venv.color]="3;33"
PSCFG[host.color]="1;32"
PSCFG[dir.color]="1;34"
PSCFG[prompt.color]="1"
PSCFG[error.color]="1;31"
PSCFG[jobs.color]="1;2;37"
PSCFG[vcs.color]="1;35"

PSCFG[venv.fmt]="(%s)"
PSCFG[error.fmt]="[%s]"
PSCFG[jobs.fmt]="*%s"
PSCFG[vcs.fmt]="(%s)"

(( UID == 0 )) && PSCFG[prompt.fmt]="#" || PSCFG[prompt.fmt]=">"
PSCFG[vicmd.prompt.fmt]=":"

PSCFG[cursor]="5"
PSCFG[vicmd.cursor]="1"

zle -N prompt-ps1 __prompt_ps1
zle -N prompt-rps1 __prompt_rps1
zle -N zle-keymap-select

# Redraws prompt when switching between vicmd and viins.
zle-keymap-select() {
  local save_prompt="$PSCFG[prompt.fmt]"
  local save_cursor="$PSCFG[cursor]"

  [[ "$KEYMAP" == "vicmd" ]] \
    && PSCFG[prompt.fmt]="$PSCFG[vicmd.prompt.fmt]" \
    && PSCFG[cursor]="$PSCFG[vicmd.cursor]"

  zle prompt-ps1
  zle reset-prompt

  PSCFG[prompt.fmt]="$save_prompt"
  PSCFG[cursor]="$save_cursor"
}

precmd_functions+=(__prompt)

# Prompt entry point. Sets `PS1` and `RPS1`.
__prompt() {
  # pipestatus will be overwritten after the first command
  __prompt_pipestatus="$pipestatus"
  [[ "$__prompt_pipestatus" =~ ^0( 0)*$ ]] \
    && __prompt_error_occurred=0 \
    || __prompt_error_occurred=1

  __prompt_ps1
  __prompt_rps1
}

# Sets `PS1`.
__prompt_ps1() {
  local venv prmpt REPLY

  [[ -n "$PSCFG[venv.fmt]" ]] && __prompt_venv; venv="$REPLY"
  __prompt_prompt; prmpt="$REPLY"

  PS1=""
  [[ -n "$venv" ]] && PS1+="$venv "
  PS1+=$'%{\e['$PSCFG[host.color]$'m%}%n@%m%{\e[0m%}'
  PS1+=$' %{\e['$PSCFG[dir.color]$'m%}%1~%{\e[0m%}'
  PS1+=" $prmpt "

  __prompt_set_cursor "$PSCFG[cursor]"
}

# Sets `RPS1`.
__prompt_rps1() {
  local vcs error bgjobs REPLY

  [[ -n "$PSCFG[error.fmt]" ]] && __prompt_error; error="$REPLY"
  [[ -n "$PSCFG[jobs.fmt]" ]] && __prompt_jobs; bgjobs="$REPLY"
  [[ -n "$PSCFG[vcs.fmt]" ]] && __prompt_vcs; vcs="$REPLY"

  RPS1=""
  [[ -n "$error" ]] && RPS1+="$error"
  [[ -n "$bgjobs" ]] && RPS1+=" $bgjobs"
  [[ -n "$vcs" ]] && RPS1+=" $vcs"
}

# Returns the PS1 `venv` component in `REPLY`.
__prompt_venv() {
  [[ -z "$VIRTUAL_ENV" ]] && REPLY="" && return

  __prompt_fmt_str "$PSCFG[venv.color]" "$PSCFG[venv.fmt]" \
                   "${VIRTUAL_ENV##*/}"
}

# Returns the PS1 `prompt` component in `REPLY`.
__prompt_prompt() {
  local color

  (( __prompt_error_occurred )) \
    && color=$PSCFG[error.color] \
    || color=$PSCFG[prompt.color]

  REPLY=$'%{\e['$color'm%}'$PSCFG[prompt.fmt]$'%{\e[0m%}'
}

# Returns the PS1 `error` component in `REPLY`.
__prompt_error() {
  (( __prompt_error_occurred )) \
    && __prompt_fmt_str "$PSCFG[error.color]" "$PSCFG[error.fmt]" \
                        "$__prompt_pipestatus" \
    || REPLY=""
}

# Returns the PS1 `jobs` component in `REPLY`.
__prompt_jobs() {
  local -i num_jobs=${#jobtexts[@]}

  (( num_jobs > 0 )) \
    && __prompt_fmt_str "$PSCFG[jobs.color]" "$PSCFG[jobs.fmt]" "$num_jobs" \
    || REPLY=""
}

# Returns the PS1 `vcs` component in `REPLY`.
__prompt_vcs() {
  local vcs color char

  __prompt_git_branch; vcs="$REPLY"

  [[ -z "$vcs" ]] && REPLY="" && return

  __prompt_fmt_str "$PSCFG[vcs.color]" "$PSCFG[vcs.fmt]" "$vcs"
}

# Returns git branch in `REPLY` (empty if no branch found).
__prompt_git_branch() {
  local head ref

  __prompt_git_head "$PWD"; head="$REPLY"
  [[ -z "$head" ]] && REPLY="" && return

  read ref < "$head"
  [[ "$ref" =~ ^ref: ]] && REPLY="${ref##*/}" || REPLY="${ref:0:6}"
}

# Returns git HEAD file path in `REPLY` (empty if no file found).
__prompt_git_head() {
  local dir="$1"
  REPLY=""

  while [[ -n "$dir" ]]; do
    [[ -r "$dir/.git/HEAD" ]] && REPLY="$dir/.git/HEAD" && return
    dir="${dir%/*}"
  done
}

# Returns string formatted for `PS1` or `RPS1` in `REPLY`.
# $1 - color code (ex. "1;31").
# $2 - format string (ex. "%s").
# $3 - string var, replaces "%s" in format string.
__prompt_fmt_str() {
  local color="$1" fmt="$2" str="$3"

  REPLY=$'%{\e['$color'm%}'${fmt//\%s/$str}$'%{\e[0m%}'
}

# Echos the escape sequence to set the cursor.
# $1 - cursor code (ex. "5").
__prompt_set_cursor() {
  echo -ne "\e[$1 q"
}
