#!/bin/bash
__dirname=$(dirname $(readlink -f $BASH_SOURCE))
export PATH=$__dirname/node_modules/.bin:$__dirname/bin:$PATH
