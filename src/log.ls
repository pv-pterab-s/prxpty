#!/usr/bin/env lsc
fs = require 'fs'
log = require 'log'
M = (s) -> console.log s; s
E = (s) -> console.error s; s

if process.stdin.setRawMode?      # missing if stdin not a tty
  process.stdin.setRawMode true

write-to-file-p = process.argv[3]?

if write-to-file-p
  fp = fs.openSync process.argv[3], 'w'
  process.stdin.on 'data', (d) ->
    fs.writeSync fp, log.msg2log(d.toString!) + '\n'
    process.stdout.write d
else
  process.stdin.on 'data', (d) ->
    process.stdout.write log.msg2log(d.toString!) + '\n'
