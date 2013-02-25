
{C} = require './const'
{Buffer} = require './browser'
{pow2,rshift,twos_compl,U32MAX} = require './util'

##=======================================================================

is_array = (x) -> Object.prototype.toString.call(x) is '[object Array]'
is_int = (f) -> Math.floor(f) is f
is_byte_array = (x) -> Object.prototype.toString.call(x) is '[object Uint8Array]'

##=======================================================================
#
# u64max_minus_i
#
# The challenge is, given a positive integer i, to express
# 2^64 - i as per standard 2's complement, and then put both
# words in the buffer stream.  There's the way it's done:
#
#   Given input i>=0, pick x and y such that i = 2^32 x + y,
#   where x,y are both positive, and both less than 2^32.
#
#   Now we can write:
# 
#       2^64 - i = 2^64 - 2^32 x - y
#
#   Factoring and rearranging:
# 
#       2^64 - i = 2^32 * (2^32 - x - 1) + (2^32 - y)
# 
#   Thus, we've written:
#
#        2^64 - i =  2^32 a + b
#
#   Where 0 <= a,b < 2^32. In particular:
#
#       a = 2^32 - x - 1
#       b = 2^32 - y
#
#   And this satisfies our need to put two positive ints into
#   stream.
# 
u64max_minus_i = (i) ->
  x = Math.floor( i / U32MAX)
  y = i % U32MAX
  a = U32MAX - x - (if y > 0 then 1 else 0)
  b = if y is 0 then 0 else U32MAX - y
  return [a, b]
  
##=======================================================================

exports.Packer = class Packer

  #-----------------------------------------

  constructor: (@_opts = {}) ->
    @_buffer = new Buffer()

  #-----------------------------------------

  output : (enc) ->
    @_buffer.toString enc
  
  #-----------------------------------------

  p : (o) ->
    switch typeof o
      when 'number'              then @p_number o
      when 'string'              then @p_utf8_string o
      when 'boolean'             then @p_boolean o
      when 'undefined'           then @p_null()
      when 'object'
        if not o?                then @p_null()
        else if is_array o       then @p_array o
        else if is_byte_array o  then @p_byte_array o
        else                     @p_obj o

  #-----------------------------------------

  p_number : (n) ->
    if not is_int n then @p_pack_double n
    else if n >= 0  then @p_positive_int n
    else                 @p_negative_int n

  #-----------------------------------------

  p_pack_double : (d) ->
    if @_opts.floats?
      @p_uint8 C.float
      @_buffer.push_float32 d
    else
      @p_uint8 C.double
      @_buffer.push_float64 d
   
  #-----------------------------------------

  p_uint8  : (b) -> @_buffer.push_uint8  b
  p_uint16 : (s) -> @_buffer.push_uint16 s
  p_uint32 : (w) -> @_buffer.push_uint32 w
  p_int8   : (b) -> @_buffer.push_int8  b
  p_int16  : (s) -> @_buffer.push_int16 s
  p_int32  : (w) -> @_buffer.push_int32 w

  #-----------------------------------------

  #
  # p_neg_int64 -- Pack integer i < -2^31 into a signed quad,
  #   up until the JS resolution cut-off at least.  
  # 
  # 
  p_neg_int64 : (i) ->
    abs_i = 0 - i
    [a,b] = u64max_minus_i abs_i
    @p_int32 a
    @p_int32 b
   
  #-----------------------------------------

  p_boolean : (b) -> @p_uint8 if b then C.true else C.false
  p_null :    ()  -> @p_uint8 C.null
   
  #-----------------------------------------

  p_array : (a) ->
    @p_len a.length, C.fix_array_min, C.fix_array_max, C.array16, C.array32
    @p e for e in a
   
  #-----------------------------------------

  p_obj : (o) ->
    n = (Object.keys o).length
    @p_len n, C.fix_map_min, C.fix_map_max, C.map16, C.map32
    for k,v of o
      @p k
      @p v
   
  #-----------------------------------------

  p_positive_int : (i) ->
    if i <= 0x7f then @p_uint8 i 
    else if i <= 0xff
      @p_uint8 C.uint8
      @p_uint8 i
    else if i <= 0xffff
      @p_uint8 C.uint16
      @p_uint16 i
    else if i < U32MAX
      @p_uint8 C.uint32
      @p_uint32 i
    else
      @p_uint8 C.uint64
      @p_uint32 Math.floor(i / U32MAX)
      @p_uint32 (i & (U32MAX - 1))

  #-----------------------------------------

  p_negative_int : (i) ->
    if i >= -32 then @p_int8 i
    else if i >= -128
      @p_uint8 C.int8
      @p_int8 i
    else if i >= -32768
      @p_uint8 C.int16
      @p_int16 i
    else if i >= -2147483648
      @p_uint8 C.int32
      @p_int32 i
    else
      @p_uint8 C.int64
      @p_neg_int64 i

  #-----------------------------------------

  p_byte_array : (b) ->
    if @_opts.byte_arrays
      @p_uint8 C.byte_array
    else
      b = Buffer.ui8a_to_binary b    
    @p_len b.length, C.fix_raw_min, C.fix_raw_max, C.raw16, C.raw32
    @_buffer.push_buffer b

  p_utf8_string : (b) ->
    # Given a string, the first thing we do is convert it to a UTF-8 sequence
    # of raw bytes in a byte array.  The character '\x8a' will be converted
    # to "\xc2\x8a".  We then encoding this string.  We need to do this conversion
    # outside the buffer class since we need to know the string length to encode
    # up here.
    b = Buffer.utf8_to_ui8a b
    @p_len b.length, C.fix_raw_min, C.fix_raw_max, C.raw16, C.raw32
    @_buffer.push_buffer b

  #-----------------------------------------

  p_len : (l, smin, smax, m, b) ->
    if l <= (smax - smin)
      @p_uint8 (l|smin)
    else if l <= 0xffff
      @p_uint8 m
      @p_uint16 l
    else
      @p_uint8 b
      @p_uint32 l

  #-----------------------------------------

##=======================================================================

# Opts can be:
#   - byte_arrays - encode 0xc4 byte arrays
#   - floats      - use floats, not double in encodings...
exports.pack = (x, enc, opts = {} ) ->
  packer = new Packer opts
  packer.p x
  packer.output enc
  
