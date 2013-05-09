
{data} = require './input'
msgpack = require 'msgpack4'
util = require 'util'

res = {}

for k, v of data
  res[k] = 
    input : v
    output : msgpack.pack(v).toString 'base64'

console.log "exports.tests = ";
console.log util.inspect(res,  { depth : null })
console.log ";"