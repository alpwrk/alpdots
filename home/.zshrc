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

# Prompt: oh-my-posh with the theme from config/oh-my-posh. Where it isn't
# installed (e.g. not in FreeBSD's pkg), a plain zsh prompt with the same look:
# path (branch*) $   (* = uncommitted changes)
if command -v oh-my-posh >/dev/null; then
	eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/mytheme.omp.toml)"
else
	autoload -Uz vcs_info add-zsh-hook
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:git:*' formats '(%b%m) '
	zstyle ':vcs_info:git:*' actionformats '(%b%m) '
	zstyle ':vcs_info:git*+set-message:*' hooks git-dirty
	+vi-git-dirty() {
		[[ -n "$(git status --porcelain 2>/dev/null | head -n 1)" ]] && hook_com[misc]='*'
	}
	add-zsh-hook precmd vcs_info
	setopt prompt_subst
	PROMPT='%F{white}%~ ${vcs_info_msg_0_}$%f '
fi

# y = yazi, but cd into the directory you were in when you quit it
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd into dir
command -v fzf >/dev/null && source <(fzf --zsh 2>/dev/null)

# zoxide: `z <part of dir>` / `zi` for interactive pick
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Machine-specific stuff (PATHs, EDITOR, ...) goes here, it's not tracked by git
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Source a zsh plugin from wherever the distro put it
# (Arch: /usr/share/zsh/plugins, FreeBSD: /usr/local/share, Debian: /usr/share)
zplug() {
	local f
	for f in /usr/share/zsh/plugins/$1/$1.zsh /usr/local/share/$1/$1.zsh /usr/share/$1/$1.zsh; do
		[ -r "$f" ] && { source "$f"; return; }
	done
}

# must be at the bottom at all times
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#000000'
zplug zsh-autosuggestions
zplug zsh-syntax-highlighting

# history-substring-search: must be sourced after syntax-highlighting.
# Up/Down search the history for what's already typed.
zplug zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down
