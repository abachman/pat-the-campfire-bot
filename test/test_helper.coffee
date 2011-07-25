# i wrote a test framework because the other ones weren't simple enough
class UnitTest
  run: () ->
    _.each _.functions(this), (func) =>
      if /^test_/.test(func)
        console.log "running #{ func }"
        try
          @[func]()
        catch e
          console.error "MAJOR MALFUNCTION!"

  assert: (truth) ->
    if truth
      console.log '.'
    else 
      err = new Error()
      console.log 'expected value to be true'
      console.log err.stack

module.exports =
  UnitTest: UnitTest
