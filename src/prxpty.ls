#!/usr/bin/env lsc
# run stty -opost before executing in case of terminal corruption under xterm
pty = require 'node-pty'
M = (s) -> console.log s; s


# cmdline arg config
if process.argv.lsc              # handle lsc exec script
  process.argv.splice 1, 1

exec = (process.argv.slice 2, 3)[0]
args = process.argv.slice 3


term = pty.spawn (exec or 'bash'), (args or []),
  name: 'xterm-color'
  cols: process.stdout.columns
  rows: process.stdout.rows
  cwd: process.env.HOME
  env: process.env

term.on 'exit', process.exit

process.stdout.on 'resize', -> term.resize(process.stdout.columns, process.stdout.rows)
term.on 'data', (d) -> process.stdout.write d

process.stdin.setRawMode true          # fails if stdin is not a tty
process.stdin.on 'data', term.write
