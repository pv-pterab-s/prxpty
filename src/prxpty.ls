#!/usr/bin/env lsc
# run stty -opost before executing in case of terminal corruption under xterm
child-process = require 'child_process'
assert = require 'assert'
pty = require 'node-pty'
shell-quote = require 'shell-quote'
{map, reverse, zip, filter, all, find-index, each} = require 'prelude-ls'
M = (s) -> console.log s; s
E = (s) -> console.error s; s



parse-args-list-helper = (argv, out) ->
  is-str-option = (.match /^-/)

  is-option-i = (list) ->
    (list[0].match /^-i/) and not (is-str-option list[1])

  is-option-o = (list) ->
    (list[0].match /^-o/) and not (is-str-option list[1])

  add-filter = (out, key, value) -> out[key].push {
    cmd: value
    number: out[key].length
    type: key
  }

  set-cmd = (out, argv) ->
    out.exec = argv[0]
    out.args = argv.slice 1

  switch
    when is-option-i argv
      add-filter out, 'I', argv[1]
      parse-args-list-helper (argv.slice 2), out
    when is-option-o argv
      add-filter out, 'O', argv[1]
      parse-args-list-helper (argv.slice 2), out
    else
      set-cmd out, argv
      out.O = reverse out.O
      out

parse-args-list = (argv) ->
  parse-args-list-helper (argv.slice 3), {I: [], O: []}

opts = parse-args-list process.argv



input-procs = []
output-procs = []
start-filter = ({cmd, number, type}) ->

  E "[INFO] starting filter #{cmd} #{type}#{number}"
  [exec, ...args] = shell-quote.parse cmd

  proc = child-process.spawn exec, args
  proc.cmd = cmd
  proc.on 'error', ->
    E "[FAIL] cmd #{cmd} (##{type}#{number})"
    process.exit 1
  proc.on 'exit', ->
    E "[INFO] exit cmd #{cmd} (##{type}#{number})"
  proc

input-procs = map start-filter, opts.I
output-procs = map start-filter, opts.O



E "[INFO] term with #{opts.exec} and #{JSON.stringify opts.args}"
term = pty.spawn (opts.exec or 'bash'), (opts.args or []),
  cols: process.stdout.columns
  rows: process.stdout.rows
  cwd: process.env.HOME
  env: process.env

term.on 'exit', ->
  if output-procs.length > 0
    output-procs[0].stdin.end!
  if input-procs.length > 0
    input-procs[0].stdin.end!
  if process.stdin.setRawMode?
    process.stdin.setRawMode false
  process.stdin.destroy!

kill-next = (procs) ->
  procs.map (proc, k) ->
    proc.on 'exit',->
      if procs[k + 1]
        procs[k + 1].stdin.end!
kill-next output-procs
kill-next input-procs

process.stdout.on 'resize', ->
  term.resize process.stdout.columns, process.stdout.rows



idx-procs = (procs) ->
  procs.map (proc, k) ->
    proc.stdin.idx = k
    proc.stdout.idx = k

emit-pipe = (tag, i, o, d, msg = '') ->
  ## desc = (p) ->
  ##   "#{p.constructor.name}" + if p.idx? then "(#{p.idx})" else ""
  ## dataLen = (d) ->
  ##   if d? then "(#{d.length})" else ""
  ## E "[#{tag}] #{dataLen d} #{desc i} -> #{desc o} #{msg}"

# output data stream on pipe O e.g,
#   T.on('data') -> O[0].stdin
#    O[0].stdout -> O[1].stdin
#    O[1].stdout -> process.stdout
# zip pipes arrangement for pipe connections,
#   output-pipes = term, (O[0], O[1]) (.stdout)
#                    V      V     \--------------V
#   input-pipes  = (O[0], O[1]) (.stdin) , process.stdout
idx-procs output-procs
output-pipes = [term] ++ output-procs.map (.stdout)
input-pipes = (output-procs.map (.stdin)) ++ [process.stdout]
(zip output-pipes, input-pipes).map ([i, o]) ->
  emit-pipe 'O', i, o
  i.on 'data', (d) ->
    emit-pipe 'O', i, o, d, 'write'
    o.write d

# input data stream on pipe I e.g.
#   process.stdin -> I[0].stdin
#   I[0].stdout -> I[1].stdin
#   I[1].stdout -> term
# zip pipes arrangement,
#   output-pipes = process.stdin  (I[0], I[1]) (.stdout)
#                       V      V----/      \--V
#   input-pipes  =    (I[0], I[1]) (.stdin)  term
idx-procs input-procs
output-pipes = [process.stdin] ++ input-procs.map (.stdout)
input-pipes = (input-procs.map (.stdin)) ++ [term]
(zip output-pipes, input-pipes).map ([i, o]) ->
  emit-pipe 'I', i, o
  i.on 'data', (d) ->
    emit-pipe 'I', i, o, d, 'write'
    o.write d

if process.stdin.setRawMode?      # missing if stdin not a tty
  process.stdin.setRawMode true
