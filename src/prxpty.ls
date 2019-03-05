#!/usr/bin/env lsc
# run stty -opost before executing in case of terminal corruption under xterm
child-process = require 'child_process'
assert = require 'assert'
pty = require 'node-pty'
shell-quote = require 'shell-quote'
{map, reverse, zip, filter, all, find-index, each} = require 'prelude-ls'
M = (s) -> console.log s; s
E = (s) -> console.error s; s



parse-args-list = (argv, out = {}) ->
  is-str-option = (.match /^-/)

  is-option-i = (list) ->
    (list[0].match /^-i/) and not (is-str-option list[1])

  is-option-o = (list) ->
    (list[0].match /^-o/) and not (is-str-option list[1])

  switch
    when is-option-i argv
      out.I = argv[1]
      parse-args-list (argv.slice 2), out
    when is-option-o argv
      out.O = argv[1]
      parse-args-list (argv.slice 2), out
    else
      [out.exec, ...out.args] = argv
      out

opts = parse-args-list process.argv.slice 3



start-filter = (cmd, type) ->
  return if not cmd?

  E "[INFO] starting filter #{type} #{cmd}"
  [exec, ...args] = shell-quote.parse cmd

  proc = child-process.spawn exec, args
  proc.cmd = cmd
  proc.on 'error', ->
    E "[FAIL] cmd (#{type}) #{cmd}"
    process.exit 1
  proc.on 'exit', ->
    E "[INFO] exit (#{type}) cmd #{cmd}"
  proc

input-proc = start-filter opts.I, 'I'
output-proc = start-filter opts.O, 'O'



E "[INFO] term with #{opts.exec} and #{JSON.stringify opts.args}"
term = pty.spawn (opts.exec or 'bash'), (opts.args or []),
  name: 'xterm-color'
  cols: process.stdout.columns
  rows: process.stdout.rows
  cwd: process.env.HOME
  env: process.env

term.on 'exit', (code) ->
  if output-proc? then output-proc.stdin.destroy!
  if input-proc? then input-proc.stdin.destroy!
  process.stdin.destroy!

process.stdout.on 'resize', ->
  term.resize process.stdout.columns, process.stdout.rows



pipe = (label = '', _in, out) ->
  E "[PIPE] #{label} #{_in.constructor.name} -> #{out.constructor.name}"
  _in.pipe out

# output data stream on pipe O e.g,
#   T.on('data') -> O[0].stdin
#    O[0].stdout -> O[1].stdin
#    O[1].stdout -> process.stdout
# zip pipes arrangement for pipe connections,
#   output-pipes = term, (O[0], O[1]) (.stdout)
#                    V      V     \--------------V
#   input-pipes  = (O[0], O[1]) (.stdin) , process.stdout
if output-proc?
  pipe 'O', term, output-proc.stdin
  pipe 'O', output-proc.stdout, process.stdout
else
  pipe 'O', term, process.stdout

# input data stream on pipe I e.g.
#   process.stdin -> I[0].stdin
#   I[0].stdout -> I[1].stdin
#   I[1].stdout -> term
# zip pipes arrangement,
#   output-pipes = process.stdin  (I[0], I[1]) (.stdout)
#                       V      V----/      \--V
#   input-pipes  =    (I[0], I[1]) (.stdin)  term
if input-proc?
  pipe 'I', process.stdin, input-proc.stdin
  pipe 'I', input-proc.stdout, term
else
  pipe 'I', process.stdin, term


if process.stdin.setRawMode?      # missing if stdin not a tty
  process.stdin.setRawMode true
