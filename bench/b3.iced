mp = require 'msgpack2'
{Packer}  = require '../src/pack'

obj = [0...10000]

class Timer
  constructor : ->
    @_start = (new Date()).getTime()
  stop : ->
    now = (new Date()).getTime()
    now - @_start

iters = 1000

mpt = new Timer()
for i in [0...iters]
  mp.pack obj
console.log "iters #{iters}: native msgpack2: #{mpt.stop()}"

ppt = new Timer()
packer = new Packer()
for i in [0...iters]
  packer.p obj
console.log "iters #{iters}: purepack:  #{ppt.stop()}"
