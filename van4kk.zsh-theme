# Enable prompt substitution
setopt prompt_subst

# Load git info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' actionformats '%F{white}[%s|%b]%f'
zstyle ':vcs_info:git:*' formats '%b'

# Pre-command hook: capture Git and prompt info
precmd() {
  vcs_info
  update_prompt_components
}

# Track command start time
preexec() {
  CMD_TIMER=$EPOCHSECONDS
}

function shorten_path() {
  local path="$1"
  local home="$HOME"

  if [[ "$path" == "$home" ]]; then
    echo "~"
    return
  fi

  if [[ "$path" == "/" ]]; then
    echo "~/👹 nether"
    return
  fi

  if [[ "$path" == $home/* ]]; then
    local rel="${path#$home/}"
    local -a parts
    IFS='/' read -A parts <<< "$rel"

    local count=${#parts[@]}

    if (( count == 1 )); then
      echo "~/${parts[1]}"
      return
    elif (( count == 2 )); then
      echo "~/${parts[1]}/${parts[2]}"
      return
    # elif (( count == 3 )); then
    #   echo "~/${parts[1]}/${parts[2]}/${parts[3]}"
    #   return
    else
      echo "../${parts[-2]}/${parts[-1]}"
      return
    fi
  else
    echo "$path"
    return
  fi
}

function process_username() {
  local username="$1"
  local max_length=13

  if (( ${#username} > max_length )); then
    echo "usr"
  else
    echo "$username"
  fi
}

function update_prompt_components() {
  local branch="${vcs_info_msg_0_}"
  local git_color=""
  local GIT_PROMPT=""
  local CMD_DURATION=""

  local USER_NAME=$(process_username "$USER")
  local SHORT_PATH=$(shorten_path "$PWD")
  
  local RETURN_STATUS=""
  local NIGHT_TIME=""
  local RIGHT_WARNINGS=""
  local CMD_INDICATOR=">"
  local LAST_EXIT_CODE_RAW=$?

  # Git branch color logic
  if [[ "$branch" == hot* || "$branch" == hotfix* ]]; then
    git_color="red"
  elif [[ "$branch" == main || "$branch" == master ]]; then
    git_color="blue"
  elif [[ "$branch" == feature* || "$branch" == fix* ]]; then
    git_color="yellow"
  elif [[ -n "$branch" ]]; then
    git_color="green"
  fi

  # Git branch display
  if [[ -n "$branch" ]]; then
    GIT_PROMPT="%F{white}(%F{$git_color}$branch%F{white})%f"
    CMD_INDICATOR=":"
  fi

  # Exit status (non-zero only)
  if [[ $LAST_EXIT_CODE_RAW -ne 0 ]]; then
    RETURN_STATUS="%F{red}✘ $LAST_EXIT_CODE_RAW%f"
  fi

  # Command duration if > 5 seconds
  if [[ -n "$CMD_TIMER" ]]; then
    local duration=$(( EPOCHSECONDS - CMD_TIMER ))
    if (( duration > 5 )); then
      CMD_DURATION="%F{magenta}${duration}s%f"
    fi
  fi

  # Night time display (00:00–07:59)
  local HOUR=$(date +%H)
  if (( HOUR < 8 )); then
    NIGHT_TIME="%F{white}[%F{yellow}%D{%H:%M}%F{white}]%f "
  fi

  # Optional: SSH session indicator
  #[[ -n "$SSH_CONNECTION" ]] && IS_SSH="%F{yellow}🔒%f " || IS_SSH=""

  # Optional: root user indicator
  #[[ $EUID -eq 0 ]] && IS_ROOT="%F{red}⚠ root%f " || IS_ROOT=""

  # Optional: Docker/WSL indicator
  #if grep -q docker /proc/1/cgroup 2>/dev/null || grep -qE '(microsoft|wsl)' /proc/version 2>/dev/null; then
  #  IS_DOCKER="%F{blue}🐳%f "
  #else
  #  IS_DOCKER=""
  #fi

  # Compose right-side prompt
  RETURN_STATUS="%(?..%F{red}%?↵%f)"
  RIGHT_WARNINGS="${RETURN_STATUS}"
  [[ -n "$CMD_DURATION" ]] && RIGHT_WARNINGS+=" ${CMD_DURATION}"
  #[[ -n "$IS_ROOT" ]] && RIGHT_WARNINGS+=" ${IS_ROOT}"
  #[[ -n "$IS_SSH" ]] && RIGHT_WARNINGS+=" ${IS_SSH}"
  #[[ -n "$IS_DOCKER" ]] && RIGHT_WARNINGS+=" ${IS_DOCKER}"

  # Final prompts
  PROMPT_LEFT="${NIGHT_TIME}%F{cyan}${USER_NAME}%f@%F{green}${SHORT_PATH}%f ${GIT_PROMPT}%F{white}${CMD_INDICATOR}%f "
  PROMPT_RIGHT="${RIGHT_WARNINGS}"
}

# Assign prompt strings
PROMPT='${PROMPT_LEFT}'
RPROMPT='${PROMPT_RIGHT}'
