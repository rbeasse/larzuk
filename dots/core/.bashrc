#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PATH=$HOME/larzuk/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export TERM=xterm-256color

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias code='codium'

if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first'
fi

if command -v bat &>/dev/null; then
  alias cat='bat'
fi

if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

# Docker helpers
function dexec() {
  CONTAINER=$(docker ps | grep -v CONTAINER | awk '-F ' '{print $NF}' | fzf)
  if [ -n "$CONTAINER" ]; then
    docker exec -it "$CONTAINER" bash
  fi
}

function dlog() {
  CONTAINER=$(docker ps | grep -v CONTAINER | awk '-F ' '{print $NF}' | fzf)
  if [ -n "$CONTAINER" ]; then
    docker logs -f "$CONTAINER"
  fi
}

# Prompt
source "$HOME/.bashprompt"

# mise
eval "$(/home/ryan/.local/bin/mise activate bash)"

eval $(ssh-agent) &>/dev/null
