# Set colors
C00="\[\033[0m\]"	# default color or grey
C01="\[\033[0;30m\]"	# black
C02="\[\033[1;30m\]"	# dark grey (bold)
C03="\[\033[0;31m\]"	# dark red
C04="\[\033[1;31m\]"	# red (bold)
C05="\[\033[0;32m\]"	# dark green
C06="\[\033[1;32m\]"	# green (bold)
C07="\[\033[0;33m\]"	# gold yellow
C08="\[\033[1;33m\]"	# yellow (bold)
C09="\[\033[0;34m\]"	# dark blue
C10="\[\033[1;34m\]"	# blue (bold)
C11="\[\033[0;35m\]"	# dark purple
C12="\[\033[1;35m\]"	# purple (bold)
C13="\[\033[0;36m\]"	# dark seagrean
C14="\[\033[1;36m\]"	# seagreen (bold)
C15="\[\033[0;37m\]"	# grey or regular white
C16="\[\033[1;37m\]"	# white (bold)

################################################

# Path edit function
_pathedit () {
if ! echo $PATH | grep -E -q "(^|:)$1($|:)" ; then
	if [ "$2" = "after" ] ; then
		PATH=$PATH:$1
	else
		PATH=$1:$PATH
	fi
fi
}

# Set PATH so it includes user's private bin if it exists
[ -d $HOME/bin ] && _pathedit $HOME/bin after

# More paths
[ -d /usr/local/sbin ] && _pathedit /usr/local/sbin
[ -d /usr/local/bin ] && _pathedit /usr/local/bin
[ -d /usr/sbin ] && _pathedit /usr/sbin
[ -d /usr/bin ] && _pathedit /usr/bin
[ -d /sbin ] && _pathedit /sbin
[ -d /bin ] && _pathedit /bin

# This function checks whether we have a given program on the system.
_have()
{
	command -v $1 &>/dev/null
}

# Miscellaneous
export PAGER='less'
export TZ='America/New_York'
export LANG='en_US.UTF-8'
export OS_TYPE=$(uname)

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell

# Bash history settings
export HISTSIZE=2000
export HISTIGNORE='&:exit:*shutdown*:*reboot*'
export HISTCONTROL='ignoreboth'
export HISTTIMEFORMAT='%F %T '
shopt -s cmdhist
shopt -s histappend

# Enable bash completion
if [ -r /etc/bash_completion ] ; then
	source /etc/bash_completion
elif [ -r $HOME/bash_completion ] ; then
	source $HOME/bash_completion
fi

# Mosh alias
if _have mosh ; then
	alias mssh='mosh'
	complete -F _ssh_hosts mssh
fi

# SSH alias with forwarding
alias ssh='ssh -A'
alias xssh='ssh -X'
alias zssh='ssh -C'
alias xzssh='ssh -X -C'

# Set LS_COLORS
if _have dircolors ; then
	if [ -r $HOME/.dir_colors ] ; then
		eval `dircolors -b $HOME/.dir_colors`
	else
		eval `dircolors -b`
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

# MySQL prompt
if _have mysql ; then
	export MYSQL_PS1='[\u@\h:\p \d]> '
fi

# Show grep in color
export GREP_OPTIONS='--color=auto'

# OS specific settings
case $OS_TYPE in
	Linux)
		export HOST_NAME=$(uname -n)
		alias ls='ls --color=auto'
		;;
	CYGWIN*)
		export HOST_NAME=$(uname -n)
		alias ls='ls --color=auto'
		;;
	Darwin)
		export HOST_NAME=$(hostname -s)
		alias ls='ls -G'
		export CLICOLOR=1
		;;
	FreeBSD)
		export HOST_NAME=$(hostname -s)
		alias ls='ls -G'
		export CLICOLOR=1
		;;
	SunOS)
		export HOST_NAME=$(uname -n)
		;;
esac

# Dynamic prompt and auto reset of ssh agent if in tmux
if [[ -n $TMUX ]] ; then
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
	if [ $USER == 'root' ] ; then
		userprompt="${C03}#"
		continueprompt="${C03}>>"
	elif [ -z $SUDO_USER ] ; then
		userprompt="${C09}>"
		continueprompt="${C09}>>"
	else
		userprompt="${C07}$"
		continueprompt="${C07}>>"
	fi
	# Change title to include user if sudoed
	if [ -z $SUDO_USER ] ; then
		title="$HOST_NAME"
	else
		title="$USER@$HOST_NAME"
	fi
	# Change working directory color if writable
	if [ -w $PWD ] ; then
		pwdcolor="${C08}"
	else
		pwdcolor="${C11}"
	fi
	# Show exit status if not zero
	if [ $exitstatus -ne 0 ] ; then
		exitcode="${C03}[${exitstatus}]"
	else
		exitcode=""
	fi
	PS1="${C08}\D{%Y-%m-%dT%H:%M:%S%z}\n${C15}[${C05}\u${C09}@${C05}\h${C09}:${pwdcolor}\w${C15}]${exitcode}${userprompt}${C00} "
	PS2="${continueprompt}${C00} "
	# Change title
	_set_title $title
}


# Change screen/tmux window and xterm/rxvt title names
_set_title()
{
        case $TERM in
                screen*)
                        echo -ne "\033k$1\033\\"
                        ;;
                xterm*|rxvt*)
                        echo -ne "\033]0;$1\007"
                        ;;
        esac
}

# SSH completion
_ssh_hosts()
{
	local prev cur opts known_hosts
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cur="${COMP_WORDS[COMP_CWORD]}"
	known_hosts="/dev/null"
	if [ -r /etc/ssh/ssh_known_hosts ] ; then
		known_hosts="/etc/ssh/ssh_known_hosts ${known_hosts} "
	fi
	if [ -r $HOME/.ssh/known_hosts ] ; then
		known_hosts="$HOME/.ssh/known_hosts ${known_hosts} "
	fi
	opts=$(cat ${known_hosts} | awk -F "," '{print $1}' | awk '{print $1}' | uniq)
	COMPREPLY=($(compgen -W "${opts}" "${cur}"))
}
complete -F _ssh_hosts ssh xssh zssh xzssh

# Start SSH agent
start_ssh_agent()
{
	if [ -z $SSH_AUTH_SOCK ] || [ ! -S $SSH_AUTH_SOCK ] ; then
		eval `ssh-agent -s`
		trap "kill $SSH_AGENT_PID" 0
		ssh-add
	fi
}

# Reset SSH agent after detaching and reattaching tmux
reset_ssh_agent()
{
	if [[ -n $TMUX ]] && [[ ! -S $SSH_AUTH_SOCK ]] ; then
		local new_ssh_auth_sock=$(tmux showenv | grep '^SSH_AUTH_SOCK' | cut -d = -f 2)
		if [[ -n $new_ssh_auth_sock ]] && [[ -S $new_ssh_auth_sock ]] ; then
			SSH_AUTH_SOCK=$new_ssh_auth_sock
		fi
	fi
}

# Function for extracting files
extract() {
	if [ -f $1 ] ; then
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
[ -z $SUDO_PATH ] && readonly SUDO_PATH=$(command -v sudo)
sudo_shim()
{
	local params suser oldterm title exitstatus
	params=$@
	suser=$(echo $params | grep -Eo '\-u [a-z0-9_-]+' | awk '{print $2}')
	oldterm=$TERM
	# Change title to include user if sudoed
	if [ -z $suser ] ; then
		title="root@$HOST_NAME"
	else
		title="$suser@$HOST_NAME"
	fi
	# Change title
	_set_title $title
	# Set TERM to xterm
	TERM='xterm'
	# Execute sudo
	if [[ -n $SUDO_PATH ]] && [[ -x $SUDO_PATH ]] ; then
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
[ -r $HOME/.bashrc-env ] && source $HOME/.bashrc-env

unset -f _have
unset -f _pathedit
