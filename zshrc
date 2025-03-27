# Remove case sensitivity
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# Prompt setup
function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}
setopt PROMPT_SUBST
PROMPT='%F{124}☭%f %F{105}%~%f %F{208}$(parse_git_branch)%f %(?.%F{105}❯%f .%F{124}(╯°□°）╯︵ ┻━┻%f '

# Homebrew setup
export HOMEBREW_BUNDLE_FILE=${HOME}/.Brewfile
export HOMEBREW_BUNDLE_NO_LOCK=true

# Add git aliases
alias ls='ls -GpF'
alias gst='git status'
alias zs='source ~/.zshrc'
alias uuid='uuidgen | tr -d '\''\n'\'' | pbcopy' uuid
# alias gcpo = '!f() { git checkout \"$1\" && git pull origin \"$1\"; }; f'

# Add asdf
. $HOME/.asdf/asdf.sh

source ~/.dotfiles/.secrets
