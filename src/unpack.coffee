
{C} = require './const'
{Buffer} = require './buffer'
{pow2,twos_compl_inv,U32MAX} = require './util'
floats = require './floats'

##=======================================================================

exports.Unpacker = class Unpacker

  constructor : ()  ->
    @_buffer = null
    @_e = []
    
  #-----------------------------------------
  
  decode : (s, enc) -> return !! (@_buffer = Buffer.decode s, enc)

  #-----------------------------------------

  u_raw : (n) ->
    @_buffer.consume_string n
   
  #-----------------------------------------

  get_error : () -> if @_e.length then @_e else null
   
  #-----------------------------------------

  u_array : (n) -> (@u() for i in [0...n])
   
  #-----------------------------------------

  u_map : (n) ->
    ret = {}
    for i in [0...n]
      ret[@u()] = @u()
    return ret
     
  #-----------------------------------------

  u_uint8 : () -> @_buffer.consume_byte()
  u_int8 : () -> twos_compl_inv @u_uint8(), 8
  u_uint16 : () ->
    v = @_buffer.consume_bytes 2
    return (v[0] << 8 | v[1])
  u_int16 : () -> twos_compl_inv @u_uint16(), 16
  u_uint32 : () ->
    v = @_buffer.consume_bytes 4
    sum = 0
    sum += b*pow2(8*(3-i)) for b,i in v
    return sum
  u_int32 : () ->
    return twos_compl_inv @u_uint32(), 32
  u_uint64 : () -> (@u_uint32() * U32MAX) + @u_uint32()

  #-----------------------------------------

  u_double : () ->
    cnv = floats.Converter.make @_buffer
    if cnv? then cnv.consume_float64()
    else @error "Sorry, no float64 decoding support"
    
  #-----------------------------------------

  u_float : () ->
    cnv = floats.Converter.make @_buffer
    if cnv? then cnv.consume_float32()
    else @error "Sorry, no float32 decoding support"
    
  #-----------------------------------------

  # This is, as usual, a bit subtle.  Here is what we get:
  #
  #     x = 2^32*a + b
  #
  # comes in out of the buffer, by calling u_uint32() as normal.
  # We seek the value x - 2^64 as the output, but we have to do it
  # in a smart way.  So we write:
  #
  #    x - 2^64 = 2^32*a + b - 2^64
  #
  # And factor:
  #
  #    x - 2^64 = 2^32(a - 2^32) + b
  #
  # And this is good enough, since (a - 2^32) is going to have a small
  # absolute value, for small values of a.
  # 
  u_int64 : () ->
    [a,b] = (@u_uint32() for i in [0...2])
    U32MAX*(a - U32MAX) + b
    
  #-----------------------------------------

  error : (e) ->
    @_e.push e
    null
   
  #-----------------------------------------

  u : () ->
    b = @_buffer.consume_byte()
    if b <= C.positive_fix_max then b
    else if b >= C.negative_fix_min and b <= C.negative_fix_max
      twos_compl_inv b, 8
    else if b >= C.fix_raw_min and b <= C.fix_raw_max
      l = (b & C.fix_raw_count_mask)
      @u_raw l
    else if b >= C.fix_array_min and b <= C.fix_array_max
      l = (b & C.fix_array_count_mask)
      @u_array l
    else if b >= C.fix_map_min and b <= C.fix_map_max
      l = (b & C.fix_map_count_mask)
      @u_map l
    else
      switch b
        when C.null  then null
        when C.true  then true
        when C.false then false
        when C.uint8 then @u_uint8()
        when C.uint16 then @u_uint16()
        when C.uint32 then @u_uint32()
        when C.uint64 then @u_uint64()
        when C.int8 then @u_int8()
        when C.int16 then @u_int16()
        when C.int32 then @u_int32()
        when C.int64 then @u_int64()
        when C.double then @u_double()
        when C.float then @u_float()
        when C.raw16 then @u_raw @u_uint16()
        when C.raw32 then @u_raw @u_uint32()
        when C.array16 then @u_array @u_uint16()
        when C.array32 then @u_array @u_uint32()
        when C.map16 then @u_map @u_uint16()
        when C.map32 then @u_map @u_uint32()
        else @error "unhandled type #{b}"
      
##=======================================================================

exports.unpack = (x, enc = 'base64') ->
  unpacker = new Unpacker
  err = null
  res = null
  if (unpacker.decode x, enc)
    res = unpacker.u()
    err = unpacker.get_error()
  else
    err = "Decoding type '#{enc}' failed"
  throw new Error err if err?
  return res
    
##=======================================================================
