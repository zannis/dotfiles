# Cache brew prefix (saves ~75ms of forking $(brew --prefix) x3)
export HOMEBREW_PREFIX="/opt/homebrew"

# Oh-My-Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="edvardm"
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git yarn brew macos colorize gh rust common-aliases docker docker-compose)

source $ZSH/oh-my-zsh.sh

# PATH Configuration (consolidated)
export PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$HOME/.docker/bin:$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.foundry/bin:$HOME/.yarn/bin:$PATH"

# Environment Variables
export EDITOR=nvim
export VISUAL=nvim
export GPG_TTY=$TTY
export LDFLAGS="-L$HOMEBREW_PREFIX/opt/ffmpeg@7/lib -L$HOMEBREW_PREFIX/opt/llvm/lib"
export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/ffmpeg@7/include -I$HOMEBREW_PREFIX/opt/llvm/include"
export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/ffmpeg@7/lib/pkgconfig"

# NVM Configuration (lazy-loaded; saves ~670ms on startup)
# First call to nvm/node/npm/npx in a session sources nvm.sh then runs the command.
export NVM_DIR="$HOME/.nvm"
_nvm_load() {
  unset -f nvm node npm npx
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
}
nvm()  { _nvm_load; nvm  "$@"; }
node() { _nvm_load; node "$@"; }
npm()  { _nvm_load; npm  "$@"; }
npx()  { _nvm_load; npx  "$@"; }

# Plugin Loading
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Cargo Environment
source "$HOME/.cargo/env"

# Completions (oh-my-zsh already runs compinit; don't duplicate)
compctl -K _gh gh
fpath=($HOME/.docker/completions $fpath)

# Cache slow eval outputs (saves ~30-50ms). Delete ~/.cache/zsh to refresh.
_cache_eval() {
  local cache="$HOME/.cache/zsh/$1.zsh"
  if [[ ! -s $cache ]]; then
    mkdir -p "${cache:h}"
    eval "$2" > "$cache"
  fi
  source "$cache"
}
_cache_eval fzf 'fzf --zsh'
command -v ngrok &>/dev/null && _cache_eval ngrok 'ngrok completion'
_cache_eval zellij 'zellij setup --generate-auto-start zsh'

# Tab completion
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh

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

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# Aliases
source ~/.aliases
