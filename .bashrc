# This function checks whether we have a given program on the system.
_have()
{
	command -v $1 &>/dev/null
}

# This function checks if interactive.
_interactive()
{
	[[ $- == *i* ]]
}

# Path edit function
_pathedit ()
{
	if ! echo "$1" | grep -Eq "(^|:)$2($|:)" &>/dev/null ; then
		if [ -n "$1" ] ; then
			if [ "$3" = "after" ] ; then
				echo "$1:$2"
			else
				echo "$2:$1"
			fi
		else
			echo "$2"
		fi
	else
		echo "$1"
	fi
}

# Set PATH so it includes user's private bin if it exists
[ -d ~/bin ] && PATH=$(_pathedit "$PATH" ~/bin after)
[ -d ~/.local/bin ] && PATH=$(_pathedit "$PATH" ~/.local/bin after)

# More paths
[ -d /usr/local/sbin ] && PATH=$(_pathedit "$PATH" /usr/local/sbin)
[ -d /usr/local/bin ] && PATH=$(_pathedit "$PATH" /usr/local/bin)
[ -d /usr/sbin ] && PATH=$(_pathedit "$PATH" /usr/sbin)
[ -d /usr/bin ] && PATH=$(_pathedit "$PATH" /usr/bin)
[ -d /sbin ] && PATH=$(_pathedit "$PATH" /sbin)
[ -d /bin ] && PATH=$(_pathedit "$PATH" /bin)

# Man paths
_have manpath && export MANPATH=$(manpath 2>/dev/null)
[ -d ~/man ] && MANPATH=$(_pathedit "$MANPATH" ~/man after)
[ -d ~/.local/man ] && MANPATH=$(_pathedit "$MANPATH" ~/.local/man after)

# Set colors
if _interactive && _have tput && (tput sgr0 &>/dev/null || tput me &>/dev/null) ; then
	CRESET="\[$(tput sgr0 || tput me)\]"	# reset all attributes
	C00="\[$(tput setaf 0 || tput AF 0)\]"	# black
	C01="\[$(tput setaf 1 || tput AF 1)\]"	# red
	C02="\[$(tput setaf 2 || tput AF 2)\]"	# green
	C03="\[$(tput setaf 3 || tput AF 3)\]"	# yellow
	C04="\[$(tput setaf 4 || tput AF 4)\]"	# blue
	C05="\[$(tput setaf 5 || tput AF 5)\]"	# magenta
	C06="\[$(tput setaf 6 || tput AF 6)\]"	# cyan
	C07="\[$(tput setaf 7 || tput AF 7)\]"	# white
fi

# Miscellaneous
export PAGER='less'
export TZ='America/New_York'
export LANG='en_US.UTF-8'
export OS_TYPE=$(uname)

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Bash history settings
HISTSIZE=10000
HISTIGNORE='&:exit:*shutdown*:*reboot*'
HISTCONTROL='ignoreboth'
HISTTIMEFORMAT='%F %T '
HISTFILE=~/.bash_history
shopt -s cmdhist
shopt -s histappend

# Enable bash completion
_interactive && {
if [ -r /etc/bash_completion ] ; then
	source /etc/bash_completion
elif [ -r ~/bash_completion ] ; then
	source ~/bash_completion
fi
}

# GnuPG
_interactive && {
export GPG_TTY=$(tty)
}

# Mosh alias
if _have mosh ; then
	alias mssh='mosh'
	complete -F _ssh_hosts mssh
fi

# SSH aliases
alias ssh='ssh -A'
alias xssh='ssh -X'
alias zssh='ssh -C'
alias xzssh='ssh -X -C'
alias issh='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

# Set LS_COLORS
if _have dircolors ; then
	if [ -r ~/.dir_colors ] ; then
		eval $(dircolors -b ~/.dir_colors)
	else
		eval $(dircolors -b)
	fi
fi

# Default to vim if vim exists
if _have vim ; then
	alias vi='vim'
	export EDITOR='vim'
	export VISUAL='vim'
else
	export EDITOR='vi'
	export VISUAL='vi'
fi

# Default web browser
if [ -n "$DISPLAY" ] && _have chromium-browser ; then
	export BROWSER='chromium-browser'
elif [ -n "$DISPLAY" ] && _have firefox ; then
	export BROWSER='firefox'
elif _have elinks ; then
	export BROWSER='elinks'
elif _have links ; then
	export BROWSER='links'
fi

# MySQL prompt
if _have mysql ; then
	export MYSQL_PS1='[\u@\h:\p \d]> '
fi

# Show grep in color
alias grep='grep --color=auto'

# Set HOST_NAME environment variable
export HOST_NAME=$(uname -n | cut -d . -f 1)

# OS specific settings
case $OS_TYPE in
	Linux)
		alias ls='ls --color=auto'
		;;
	CYGWIN*)
		alias ls='ls --color=auto'
		;;
	Darwin)
		alias ls='ls -G'
		export CLICOLOR=1
		;;
	FreeBSD)
		alias ls='ls -G'
		export CLICOLOR=1
		;;
esac

# Dynamic prompt and auto reset of ssh agent if in tmux
if [ -n "$TMUX" ] ; then
	PROMPT_COMMAND='_prompt_builder; reset_ssh_agent;'
else
	PROMPT_COMMAND='_prompt_builder;'
fi

# Prompt builder
_prompt_builder()
{
	local exitstatus=$?
	local userprompt continueprompt title pwdcolor exitcode
	# Change prompt if root or sudoed
	if [ "$USER" = "root" ] ; then
		userprompt="${C01}#"
		continueprompt="${C01}>>"
	elif [ -z "$SUDO_USER" ] ; then
		userprompt="${C04}>"
		continueprompt="${C04}>>"
	else
		userprompt="${C03}$"
		continueprompt="${C03}>>"
	fi
	# Change title to include user if sudoed
	if [ -z "$SUDO_USER" ] ; then
		title="$HOST_NAME"
	else
		title="$USER@$HOST_NAME"
	fi
	# Change working directory color if writable
	if [ -w "$PWD" ] ; then
		pwdcolor="${C03}"
	else
		pwdcolor="${C05}"
	fi
	# Show exit status if not zero
	if [ $exitstatus -ne 0 ] ; then
		exitcode="${C01}[${exitstatus}]"
	else
		exitcode=""
	fi
	# Show virtual environment
	if [ -n "$VIRTUAL_ENV" ]; then
		virtualenv="${C07}($(basename $VIRTUAL_ENV))"
	else
		virtualenv=""
	fi
	PS1="${CRESET}${C03}\D{%Y-%m-%dT%H:%M:%S%z}\n${C07}${virtualenv}[${C02}\u${C04}@${C02}\h${C04}:${pwdcolor}\w${C07}]${exitcode}${userprompt}${CRESET} "
	PS2="${CRESET}${continueprompt}${CRESET} "
	# Change title
	_set_title $title
}

# Change screen/tmux window and xterm/rxvt title names
_set_title()
{
	if [ -n "$1" ] && [ -t 1 ] ; then
		case $TERM in
			screen*)
				echo -ne "\ek$1\e\\"
				;;
			xterm*|rxvt*)
				echo -ne "\e]0;$1\a"
				;;
		esac
	fi
}

# SSH completion
_ssh_hosts()
{
	local prev cur opts known_hosts
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cur="${COMP_WORDS[COMP_CWORD]}"
	[ -r /etc/ssh/ssh_known_hosts ] && known_hosts="/etc/ssh/ssh_known_hosts"
	[ -r ~/.ssh/known_hosts ] && known_hosts="$HOME/.ssh/known_hosts ${known_hosts}"
	[ -n "$known_hosts" ] && opts=$(grep -Eoh -e '^\w+' -e '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' ${known_hosts})
	COMPREPLY=($(compgen -W "${opts}" "${cur}"))
}
complete -F _ssh_hosts ssh xssh zssh xzssh issh

# Start SSH agent
start_ssh_agent()
{
	if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ] ; then
		eval $(ssh-agent -s)
		trap "kill $SSH_AGENT_PID" 0
		ssh-add
	fi
}

# Reset SSH agent after detaching and reattaching tmux
reset_ssh_agent()
{
	if [ -n "$TMUX" ] && [ ! -S "$SSH_AUTH_SOCK" ] ; then
		local new_ssh_auth_sock=$(tmux showenv SSH_AUTH_SOCK | cut -d = -f 2)
		if [ -n "$new_ssh_auth_sock" ] && [ -S "$new_ssh_auth_sock" ] ; then
			SSH_AUTH_SOCK=$new_ssh_auth_sock
		fi
	fi
}

# Start GPG agent
start_gpg_agent()
{
	if [ -z "$GPG_AGENT_INFO" ] || [ ! -S $(echo $GPG_AGENT_INFO | cut -d: -f 1) ] ; then
		eval $(gpg-agent -s --daemon)
		trap "kill $(echo $GPG_AGENT_INFO | cut -d: -f 2)" 0
	fi
}

# Function for extracting files
extract() {
	if [ -f "$1" ] ; then
		case $1 in
			*.tar.bz2)	tar xvjf $1	;;
			*.tar.gz)	tar xvzf $1	;;
			*.bz2)		bunzip2 $1	;;
			*.rar)		unrar x $1	;;
			*.gz)		gunzip $1	;;
			*.tar)		tar xvf $1	;;
			*.tbz2)		tar xvjf $1	;;
			*.tgz)		tar xvzf $1	;;
			*.zip)		unzip $1	;;
			*.Z)		uncompress $1	;;
			*.7z)		7z x $1		;;
			*)	echo "Uknown Archive Type for '$1'"; return 2 ;;
		esac
	else
		echo "File Not Found '$1'"
		return 1
	fi
}
complete -f -X '!*.@(tar.bz2|tar.gz|bz2|rar|gz|tar|tbz2|tgz|zip|Z|7z)' extract

# Shim for sudo to change TITLE and TERM
_have sudo && {
# Set sudo path env variable
[ -z "$SUDO_PATH" ] && readonly SUDO_PATH=$(command -v sudo)
sudo_shim()
{
	local params suser oldterm title exitstatus
	params=$@
	suser=$(echo $params | grep -Eo '\-[a-zA-Z]+u [a-z0-9_-]+' | cut -d ' ' -f 2 | head -n 1)
	oldterm=$TERM
	# Change title to include user if sudoed
	if [ -z "$suser" ] ; then
		title="root@$HOST_NAME"
	else
		title="$suser@$HOST_NAME"
	fi
	# Change title
	_set_title $title
	# Set TERM to xterm
	TERM='xterm'
	# Execute sudo
	if [ -n "$SUDO_PATH" ] && [ -x "$SUDO_PATH" ] ; then
		$SUDO_PATH $params
		exitstatus=$?
	fi
	# Reset TERM to old TERM
	TERM=$oldterm
	return $exitstatus
}
alias sudo='sudo_shim'
}

# Include .bashrc-env if it exists for environment specific settings
[ -r ~/.bashrc-env ] && source ~/.bashrc-env

unset -f _have
unset -f _interactive
unset -f _pathedit
