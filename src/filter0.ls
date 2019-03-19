#!/usr/bin/env lsc
require 'debug'

process.stdin.on 'data', (d) ->
  process.stdout.write d
