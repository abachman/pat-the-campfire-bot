{spawn} = require 'child_process'
util    = require 'util'
jasmine = require 'jasmine-node'

task 'build', 'compile app', ->
  proc =         spawn 'coffee', ['-c', '-o', 'lib/', 'src/']
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) -> process.exit(1) if status != 0

task 'spec', 'run jasmine-node spec suite', ->
  invoke 'build'
  require 'jasmine-node'
  target = process.cwd() + '/spec'
  jasmine.executeSpecsInFolder target, (runner, log) ->
    process.exit(runner.results().failedCount)
  , false, true, "_spec.coffee$"

