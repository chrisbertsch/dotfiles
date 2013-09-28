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

# Set PATH so it includes user's private bin if it exists
if [ -d $HOME/bin ] ; then
	PATH=$HOME/bin:$PATH
fi

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
if [ -f /etc/bash_completion ] ; then
	source /etc/bash_completion
elif [ -f $HOME/bash_completion ] ; then
	source $HOME/bash_completion &> /dev/null
fi

# Mosh alias
if [ -e /usr/bin/mosh ] ; then
	alias mssh='mosh'
	complete -F _ssh_hosts mssh
fi

# SSH alias with forwarding
alias ssh='ssh -A'
alias xssh='ssh -X'
alias zssh='ssh -C'
alias xzssh='ssh -X -C'

# Set LS_COLORS
if [ -e /usr/bin/dircolors ] ; then
	if [ -f $HOME/.dir_colors ] ; then
		eval `dircolors -b $HOME/.dir_colors`
	else
		eval `dircolors -b`
	fi
fi

# Default to vim if vim exists
if [ -e /usr/bin/vim ] ; then
	alias vi='vim'
	export EDITOR='vim'
	export VISUAL='vim'
else
	export EDITOR='vi'
	export VISUAL='vi'
fi

# MySQL prompt
if [ -e /usr/bin/mysql ] ; then
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
	exitstatus=$?
	# Date Time in ISO-8601 format
	date_time=$(date +'%Y-%m-%dT%H:%M:%S%z')
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
	PS1="${C08}${date_time}\n${C15}[${C05}\u${C09}@${C05}\h${C09}:${pwdcolor}\w${C15}]${exitcode}${userprompt}${C00} "
	PS2="${continueprompt}${C00} "
	# Change screen/tmux window and xterm title names
	case $TERM in
		screen*)
			echo -ne "\033k$title\033\\"
			;;
		xterm*)
			echo -ne "\033]0;$title\007"
			;;
	esac
}

# SSH tab complete function
_ssh_hosts()
{
	local prev cur opts known_hosts
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cur="${COMP_WORDS[COMP_CWORD]}"
	known_hosts="/dev/null"
	if [ -f /etc/ssh/ssh_known_hosts ] ; then
		known_hosts="/etc/ssh/ssh_known_hosts ${known_hosts} "
	fi
	if [ -f $HOME/.ssh/known_hosts ] ; then
		known_hosts="$HOME/.ssh/known_hosts ${known_hosts} "
	fi
	opts=$(cat ${known_hosts} | awk -F "," '{print $1}' | awk '{print $1}' | uniq)
	COMPREPLY=($(compgen -W "${opts}" ${cur}))
}
complete -F _ssh_hosts ssh xssh zssh xzssh

# Start SSH agent
start_ssh_agent()
{
	sshagentpath=/usr/bin/ssh-agent
	sshagentargs='-s'
	if [[ -z $SSH_AUTH_SOCK ]] && [[ -x $sshagent ]] ; then
		eval `$sshagentpath $sshagentargs`
		trap "kill $SSH_AGENT_PID" 0
		ssh-add
	fi
}

# Reset SSH agent after detaching and reattaching tmux
reset_ssh_agent()
{
	if [[ -n $TMUX ]] ; then
		new_ssh_auth_sock=$(tmux showenv | grep '^SSH_AUTH_SOCK' | cut -d = -f 2)
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
			*)	echo "dont know what to do with '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid archive type"
	fi
}
complete -f -X '!*.@(tar.bz2|tar.gz|bz2|rar|gz|tar|tbz2|tgz|zip|Z|7z)' extract

# Shim for sudo to change TITLE and TERM
_sudo()
{
	sudopath=/usr/bin/sudo
	params=$@
	suser=$(echo $params | grep -Eo '\-u \w+' | awk '{print $2}')
	oldterm=$TERM
	# Change title to include user if sudoed
	if [ -z $suser ] ; then
		title="root@$HOST_NAME"
	else
		title="$suser@$HOST_NAME"
	fi
	# Change screen/tmux window and xterm title names
	case $TERM in
		screen*)
			echo -ne "\033k$title\033\\"
			;;
		xterm*)
			echo -ne "\033]0;$title\007"
			;;
	esac
	# Set TERM to xterm-256color
	TERM='xterm-256color'
	# Execute sudo
	$sudopath $params
	# Reset TERM to old TERM
	TERM=$oldterm
}
alias sudo='_sudo'

# Include .bashrc-env if it exists for environment specific settings
if [ -f $HOME/.bashrc-env ] ; then
	source $HOME/.bashrc-env
fi
