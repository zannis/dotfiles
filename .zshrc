# Oh-My-Zsh Configuration
export ZSH="/Users/zannis/.oh-my-zsh"
ZSH_THEME="edvardm"
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git yarn brew macos colorize gh rust common-aliases docker docker-compose)

source $ZSH/oh-my-zsh.sh

# PATH Configuration
export PATH="$PATH:~/.yarn/bin"
export PATH="$PATH:$HOME/.foundry/bin"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export PATH="$HOME/.docker/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Environment Variables
export GPG_TTY=$(tty)
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"

# Plugin Loading
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Cargo Environment
source "$HOME/.cargo/env"

# Completions and Autoloads
autoload -Uz compinit && compinit
compctl -K _gh gh
eval "$(fzf --zsh)"

# Docker CLI completions
fpath=(/Users/zannis/.docker/completions $fpath)

# Tab completion
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# Custom Functions
postid() {
  decimal=$(pbpaste)
  result=$(echo "obase=16; $decimal" | bc | tr '[:upper:]' '[:lower:]')
  final="DECODE('$result', 'hex')"
  echo "$final" | pbcopy
}

refreshMetadata() {
  if [ -z "$1" ]; then
    echo "Usage: refreshMetadata <post_id>"
    return 1
  fi
  
  POST_ID="$1"
  
  curl -X POST \
    -H "Content-Type: application/json" \
    -d "{
        \"query\": \"mutation { refreshMetadata(request: { entity: { post: \\\"$POST_ID\\\" } }) { id } }\"
    }" \
    https://api.lens.xyz
}

# Aliases
source ~/.aliases
alias claude="/Users/zannis/.claude/local/claude"