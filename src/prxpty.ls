#!/usr/bin/env lsc
# run stty -opost before executing in case of terminal corruption under xterm

console.log 'hey'

# pty = require 'node-pty'

# term = pty.spawn 'bash', [],
#   name: 'xterm-color'
#   cols: process.stdout.columns
#   rows: process.stdout.rows
#   cwd: process.env.HOME
#   env: process.env

# term.on 'exit', process.exit

# process.stdout.on 'resize', () -> term.resize(process.stdout.columns, process.stdout.rows)
# term.on 'data', (d) -> process.stdout.write

# process.stdin.setRawMode true          # fails if stdin is not a tty
# process.stdin.on 'data', term.write
