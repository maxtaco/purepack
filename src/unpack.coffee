
{C} = require './const'
{Buffer} = require './buffer'

##=======================================================================

exports.Unpacker = class Unpacker

  constructor : ()  -> @_buffer = null
  decode : (s, enc) -> return !! (@_buffer = Buffer.decode s, enc)
    

##=======================================================================

exports.unpack = (x) -> null
