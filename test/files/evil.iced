purepack = require '../../lib/main'

stack_smashers = [
 (0x91 for i in [0...10000]).concat([ 0x2 ])
 [].concat(([0x81,0xa1,0x61] for i in [0...10000])...).concat([ 0x2 ])
]

exports.evil_smashers= (T,cb) ->
  for s in stack_smashers
    b = new Buffer s
    try
      purepack.unpack b
      T.assert false
    catch e
      T.assert e
      T.equal e.toString(), 'RangeError: Maximum call stack size exceeded'

  cb null

exports.big_array = (T,cb) ->
  b = new Buffer [0xdd, 0xee, 0xee, 0xee, 0xee, 0x01 ]
  try
    purepack.unpack b
    T.assert false
  catch e
    T.assert e
    T.equal e.toString(), 'Error: read off end of buffer'
  cb null

exports.big_map = (T,cb) ->
  b = new Buffer [0xdf, 0xee, 0xee, 0xee, 0xee, 0xa1, 0x61, 0x01 ]
  try
    purepack.unpack b
    T.assert false
  catch e
    T.assert e
    T.equal e.toString(), 'Error: read off end of buffer'
  cb null

exports.big_string = (T,cb) ->
  b = new Buffer [0xdb, 0xee, 0xee, 0xee, 0xee, 0x01 ]
  try
    purepack.unpack b
    T.assert false
  catch e
    T.assert e
    T.equal e.toString(), 'Error: Corruption: asked for 4008636142 bytes, but only 1 available'
  cb null

exports.big_blob = (T,cb) ->
  b = new Buffer [0xc6, 0xee, 0xee, 0xee, 0xee, 0x01, 0x01, 0x01 ]
  try
    purepack.unpack b
    T.assert false
  catch e
    T.assert e
    T.equal e.toString(), 'Error: Corruption: asked for 4008636142 bytes, but only 3 available'
  cb null