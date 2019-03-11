#!/usr/bin/env lsc
log = require 'log'
M = (s) -> console.log s; s



if process.stdin.setRawMode?      # missing if stdin not a tty
  process.stdin.setRawMode true

process.stdin.on 'data', (d) ->
  process.stdout.write (log.msg2log d) + '\n'
