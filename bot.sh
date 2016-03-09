#!/bin/bash --login

source ~/.rvm/scripts/rvm

rvm use 2.3.0

while true; do ruby ./main.rb; done
