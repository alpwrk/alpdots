export ZSH="/usr/share/oh-my-zsh"
ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"
ZSH_THEME="gentoo"
plugins=(git sudo)
source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"

# Completion: menu to pick from, case-insensitive
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# y = yazi, but cd into the directory you were in when you quit it
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# Machine-specific stuff (PATHs, EDITOR, ...) goes here, it's not tracked by git
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# must be at the bottom at all times
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#000000'
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
