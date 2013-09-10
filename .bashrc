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

export PAGER='less'
export TZ='America/New_York'
export LANG='en_US.UTF-8'

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
if [ -f "/etc/bash_completion" ] ; then
	source "/etc/bash_completion"
elif [ -f "$HOME/bash_completion" ] ; then
	source "$HOME/bash_completion" &> /dev/null
fi

# Mosh alias
if [ -e "/usr/bin/mosh" ] ; then
	alias mssh='mosh'
	complete -F _ssh_hosts mssh
fi

# SSH alias with forwarding
alias ssh='ssh -A'
alias xssh='ssh -X'
alias zssh='ssh -C'
alias xzssh='ssh -X -C'

# Set LS_COLORS
if [ -e "/usr/bin/dircolors" ] && [ -f "$HOME/.dir_colors" ] ; then
	eval `dircolors -b $HOME/.dir_colors`
elif [ -e "/usr/bin/dircolors" ] ; then
	eval `dircolors -b`
fi

# Default to vim if vim exists
if [ -e "/usr/bin/vim" ] ; then
	alias vi='vim'
	export EDITOR='vim'
	export VISUAL='vim'
else
	export EDITOR='vi'
	export VISUAL='vi'
fi

# If 256 colors
if [[ $TERM =~ '256color' ]] ; then
	echo -e "\e[38;05;1m2\e[38;05;2m5\e[38;05;3m6 \e[38;05;4mC\e[38;05;5mO\e[38;05;6mL\e[38;05;7mO\e[38;05;8mR\e[38;05;9mS\e[0m"
fi

# Show grep in color
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# OS specific settings
case `uname` in
	Linux)
		export HOST_NAME=`uname -n`
		alias ls='ls --color=auto'
		;;
	CYGWIN*)
		export HOST_NAME=`uname -n`
		alias ls='ls --color=auto'
		;;
	Darwin)
		export HOST_NAME=`hostname -s`
		alias ls='ls -G'
		export CLICOLOR=1
		;;
	FreeBSD)
		export HOST_NAME=`hostname -s`
		alias ls='ls -G'
		export CLICOLOR=1
		;;
	SunOS)
		export HOST_NAME=`uname -n`
		alias ls='gls --color=auto'
		alias grep='ggrep --color=auto'
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
	EXITSTATUS=$?
	# Change prompt if root or sudoed
	if [ $USER == "root" ] ; then
		USERPROMPT="${C03}#"
		CONTINUEPROMPT="${C03}>>"
	elif [ -z $SUDO_USER ] ; then
		USERPROMPT="${C09}>"
		CONTINUEPROMPT="${C09}>>"
	else
		USERPROMPT="${C07}$"
		CONTINUEPROMPT="${C07}>>"
	fi
	# Change title to include user if sudoed
	if [ -z $SUDO_USER ] ; then
		TITLE=$HOST_NAME
	else
		TITLE="$USER@$HOST_NAME"
	fi
	# Change working directory color if writable
	if [ -w $PWD ] ; then
		PWDCOLOR="${C08}"
	else
		PWDCOLOR="${C11}"
	fi
	# Show exit status if not zero
	if [ $EXITSTATUS -ne 0 ] ; then
		EXITCODE="${C03}[${EXITSTATUS}]"
	else
		EXITCODE=""
	fi

	PS1="${C15}[${C05}\u${C09}@${C05}\h${C09}:${PWDCOLOR}\w${C15}]${EXITCODE}${USERPROMPT}${C00} "
	PS2="${CONTINUEPROMPT}${C00} "

	# Change screen/tmux window and xterm title names
	case $TERM in
        	screen*)
			echo -ne "\033k$TITLE\033\\"
			;;
		xterm*)
			echo -ne "\033]0;$TITLE\007"
			;;
	esac
}

# Set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
	PATH=$HOME/bin:$PATH
fi

# MySQL prompt
if [ -e "/usr/bin/mysql" ] ; then
        export MYSQL_PS1='[\u@\h:\p \d]> '
fi

# SSH tab complete function
_ssh_hosts()
{
	local prev cur opts known_hosts
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cur="${COMP_WORDS[COMP_CWORD]}"
	known_hosts="/dev/null"
	if [ -f "/etc/ssh/ssh_known_hosts" ] ; then
		known_hosts="/etc/ssh/ssh_known_hosts $known_hosts"
	fi
	if [ -f "$HOME/.ssh/known_hosts" ] ; then
		known_hosts="$HOME/.ssh/known_hosts $known_hosts"
	fi
	opts=$(cat $known_hosts | awk -F "," '{print $1}' | awk '{print $1}' | uniq)
	COMPREPLY=($(compgen -W "${opts}" ${cur}))
}

complete -F _ssh_hosts ssh xssh zssh xzssh

# Start SSH agent
start_ssh_agent()
{
	SSHAGENT=/usr/bin/ssh-agent
	SSHAGENTARGS="-s"
	if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ] ; then
		eval `$SSHAGENT $SSHAGENTARGS`
		trap "kill $SSH_AGENT_PID" 0
		ssh-add
	fi
}

# Reset SSH agent after detaching and reattaching tmux
reset_ssh_agent()
{
	if [[ -n $TMUX ]] ; then
		NEW_SSH_AUTH_SOCK=`tmux showenv | grep '^SSH_AUTH_SOCK' | cut -d = -f 2`
		if [[ -n $NEW_SSH_AUTH_SOCK ]] && [[ -S $NEW_SSH_AUTH_SOCK ]] ; then
			SSH_AUTH_SOCK=$NEW_SSH_AUTH_SOCK
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

# Include .bashrc-env if it exists for environment specific settings
if [ -f "$HOME/.bashrc-env" ] ; then
	source "$HOME/.bashrc-env"
fi
