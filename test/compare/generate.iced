
{data} = require './input'
msgpack = require 'msgpack4'

res = {}

for k, v of data
  res[k] = 
    input : v
    output : msgpack.pack(v).toString 'base64'

console.log "exports.tests = ";
console.log res
console.log ";"