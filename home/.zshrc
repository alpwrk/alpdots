# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space extended_history

# Misc options
setopt auto_cd interactive_comments

export PATH="$HOME/.local/bin:$PATH"

# Completion: menu to pick from, case-insensitive
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Key bindings (Home/End/Delete, Ctrl+Left/Right)
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Prompt: oh-my-posh with the theme from config/oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/mytheme.omp.toml)"

# y = yazi, but cd into the directory you were in when you quit it
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd into dir
source <(fzf --zsh)

# zoxide: `z <part of dir>` / `zi` for interactive pick
eval "$(zoxide init zsh)"

# Machine-specific stuff (PATHs, EDITOR, ...) goes here, it's not tracked by git
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# must be at the bottom at all times
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#000000'
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history-substring-search: must be sourced after syntax-highlighting.
# Up/Down search the history for what's already typed.
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down
