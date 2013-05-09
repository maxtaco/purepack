purepack = require '../../lib/main'

{tests} = require '../pack/data.js'

for k,v of tests
  exports[k] = (T, cb) ->
    mine = purepack.pack v.input
    T.equal mine, v.output, k
    cb()