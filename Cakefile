fs            = require 'fs'
{spawn}       = require('iced-utils').spawn

task 'test', "run the test suite", (cb) ->
  await spawn [ "test/run.iced"], defer status
  process.exit(1) if status != 0
  cb() if typeof cb is 'function'
