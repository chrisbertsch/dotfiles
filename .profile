# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

## if running bash start zsh
#if [ -n "$BASH_VERSION" ] && tty --silent ; then
#    # if zsh is installed
#    if [ -x "/usr/bin/zsh" ] ; then
#	exec /usr/bin/zsh --login
#    # if zsh is in $HOME/bin
#    elif [ -x "$HOME/bin/zsh" ] ; then
#	exec $HOME/bin/zsh --login
#    fi
#fi

# if running bash
if [ -n "$BASH_VERSION" ] ; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ] ; then
	source "$HOME/.bashrc"
    fi
fi

# if running zsh
if [ -n "$ZSH_VERSION" ] ; then
    # include .zshrc if it exists
    if [ -f "$HOME/.zshrc" ] ; then
        source "$HOME/.zshrc"
    fi
fi
