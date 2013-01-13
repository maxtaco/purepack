
{C} = require './const'
{Buffer} = require './buffer'

#-----------------------------------------------------------------------

is_array = (x) -> Object.prototype.toString.call(x) is '[object Array]'
is_int = (f) -> (f|0) is f

##=======================================================================

exports.Packer = class Packer

  #-----------------------------------------

  constructor: ->
    @_buffer = new Buffer()

  #-----------------------------------------

  output : (enc) ->
    @_buffer.toString enc
  
  #-----------------------------------------

  p : (o) ->
    switch typeof o
      when 'number'  then @p_number o
      when 'string'  then @p_bytes o
      when 'boolean' then @p_boolean o
      when 'object'
        if not o?          then @p_null()
        else if is_array o then @p_array o
        else                    @p_obj o

  #-----------------------------------------

  p_number : (n) ->
    if not is_int n then @p_pack_double n
    else if n >= 0  then @p_positive_int n
    else                 @p_negative_int n

  #-----------------------------------------

  p_byte : (b) -> @_buffer.push_byte b
  p_int  : (i) -> @_buffer.push_int i
  p_short: (s) -> @_buffer.push_short s

  #-----------------------------------------

  p_boolean : (b) -> @p_byte if b then C.true else C.false
  p_null :    ()  -> @p_byte C.null
   
  #-----------------------------------------

  p_array : (a) ->
    @p_len a.length, C.fix_array_min, C.array16, C.array32
    @p e for e in a
   
  #-----------------------------------------

  p_obj : (o) ->
    n = (Object.keys o).length
    @p_len n, C.fix_map_min, C.map16, C.map32
    for k,v of o
      @p k
      @p v
   
  #-----------------------------------------

  p_positive_int : (i) ->
    if i <= 0x7f then @p_byte i 
    else if i <= 0xff
      @p_byte C.uint8
      @p_byte i
    else if i <= 0xffff
      @p_byte C.uint16
      @p_short i
    else if i <= 0xffffffff
      @p_byte C.uint32
      @p_int i
    else
      @p_byte C.uint64
      @p_int (i >> 32)
      @p_int (i & 0xffffffff)

  #-----------------------------------------

  p_negative_int : (i) ->
    if i >= -32 then @p_byte (0x100 + i)
    else if i >= -128
      @p_byte C.int8
      @p_byte (0x100 + i)
    else if i >= -32768
      @p_byte C.int16
      @p_short (0x10000 + i)
    else if i >= -214748364
      @p_byte C.int32
      @p_int (0x100000000 + i)
    else
      @p_byte C.int64
      @p_int (i >> 32)
      @p_int (i & 0xffffffff)

  #-----------------------------------------

  p_bytes : (b) ->
    @p_len b.length, C.fix_raw, C.raw16, C.raw32
    @_buffer.push_bytes b

  #-----------------------------------------

  p_len : (l, s, m, b) ->
    if l <= 0xf
      @p_byte (l|s)
    else if l <= 0xffff
      @p_byte m
      @p_short l
    else
      @p_byte b
      @p_int l

  #-----------------------------------------

##=======================================================================

exports.pack = (x, enc) ->
  packer = new Packer()
  packer.p x
  packer.output enc
  
