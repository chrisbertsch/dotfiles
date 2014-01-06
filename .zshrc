# This function checks whether we have a given program on the system.
_have()
{
	command -v $1 &>/dev/null
}

# Set colors
if _have tput ; then
	C00="%{$(tput setaf 0 || tput AF 0)%}"	# black
	C01="%{$(tput setaf 1 || tput AF 1)%}"	# red
	C02="%{$(tput setaf 2 || tput AF 2)%}"	# green
	C03="%{$(tput setaf 3 || tput AF 3)%}"	# yellow
	C04="%{$(tput setaf 4 || tput AF 4)%}"	# blue
	C05="%{$(tput setaf 5 || tput AF 5)%}"	# magenta
	C06="%{$(tput setaf 6 || tput AF 6)%}"	# cyan
	C07="%{$(tput setaf 7 || tput AF 7)%}"	# white
fi

# Path edit function
_pathedit ()
{
	if ! echo $PATH | grep -Eq "(^|:)$1($|:)" ; then
		if [ "$2" == "after" ] ; then
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

# Miscellaneous
export PAGER='less'
export TZ='America/New_York'
export LANG='en_US.UTF-8'
export OS_TYPE=$(uname)
bindkey -e
zstyle :compinstall filename '~/.zshrc'
autoload -Uz compinit
compinit

# Zsh history settings
HISTSIZE=2000
SAVEHIST=2000
HISTIGNORE='&:exit:*shutdown*:*reboot*'
HISTCONTROL='ignoreboth'
HISTTIMEFORMAT='%F %T '
HISTFILE=~/.zsh_history
setopt appendhistory

# Mosh alias
if _have mosh ; then
	alias mssh='mosh'
fi

# SSH alias with forwarding
alias ssh='ssh -A'
alias xssh='ssh -X'
alias zssh='ssh -C'
alias xzssh='ssh -X -C'
alias issh='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

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

# Go Lang
if ! _have go && [ -d $HOME/go ] && [ -d $HOME/go/bin ] && [ -r $HOME/go/ARCH ] && [ "`uname`-`uname -m`" == "$(<$HOME/go/ARCH)" ] ; then
	export GOROOT=$HOME/go
	_pathedit $HOME/go/bin after
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

# Prompt builder and precmd
precmd()
{
	local exitstatus=$?
	local userprompt continueprompt title pwdcolor exitcode
	# Change prompt if root or sudoed
	if [ $USER = 'root' ] ; then
		userprompt="${C01}#"
		continueprompt="${C01}>>"
	elif [ -z $SUDO_USER ] ; then
		userprompt="${C04}>"
		continueprompt="${C04}>>"
	else
		userprompt="${C03}$"
		continueprompt="${C03}>>"
	fi
	# Change title to include user if sudoed
	if [ -z $SUDO_USER ] ; then
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
	PS1="${C03}%D{%Y-%m-%dT%H:%M:%S%z} 
${C07}[${C02}%n${C04}@${C02}%m${C04}:${pwdcolor}%~${C07}]${exitcode}${userprompt}${C07} "
	PS2="${continueprompt}${C00} "
	# Change title
	_set_title $title
	# Auto reset of ssh agent
        [[ -n $TMUX ]] && reset_ssh_agent

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
