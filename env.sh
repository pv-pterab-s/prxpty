#!/bin/bash
export PRXPTY=$(dirname $(readlink -f $BASH_SOURCE))
export PATH=$PRXPTY/node_modules/.bin:$__dirname/bin:$PATH
