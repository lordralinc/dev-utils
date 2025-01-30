#!/bin/bash

scripts_path="$(dirname $(readlink -f $0))"
sudo chmod +x ${scripts_path}/*

if [ -f ~/.bashrc ]; then
    echo "export PATH=\$PATH:$scripts_path" >> ~/.zshrc

    if [[ $(ps -p $$ -o 'comm=') == "bash" ]] 
    then
        source ~/.bashrc
    fi
fi

if [ -f ~/.zshrc ]; then
    echo "export PATH=\$PATH:$scripts_path" >> ~/.zshrc
    if [[ $(ps -p $$ -o 'comm=') == "zsh" ]] 
    then
        source ~/.zshrc
    fi
fi