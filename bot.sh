#!/bin/bash --login

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ~/.rvm/scripts/rvm

rvm use 2.3.0

cd $DIR

while true; do ruby ./main.rb ; done
