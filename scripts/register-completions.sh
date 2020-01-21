
# parameter completions for *nix shell

if   [[ "$SHELL" = */zsh ]]; then
  # zsh parameter completion for xmake
  _xmake_zsh_complete() 
  {
    local completions=("$(XMAKE_SKIP_HISTORY=1 xmake lua --root private.utils.complete 0 nospace "$words")")
    reply=( "${(ps:\n:)completions}" )
  }
  compctl -f -S "" -K _xmake_zsh_complete xmake
elif [[ "$SHELL" = */bash ]]; then
    # bash parameter completion for xmake
  _xmake_bash_complete()
  {
    local word=${COMP_WORDS[COMP_CWORD]}
    local completions
    completions="$(XMAKE_SKIP_HISTORY=1 xmake lua --root private.utils.complete "${COMP_POINT}" "conf" "${COMP_LINE}" 2>/dev/null)"
    if [ $? -ne 0 ]; then
      completions=""
    fi
    COMPREPLY=( $(compgen -W "$completions" -- "$word") )
  }
  complete -o default -o nospace -F _xmake_bash_complete xmake
fi

