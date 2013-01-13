
{C} = require './const'
{Buffer} = require './buffer'

#-----------------------------------------------------------------------

is_array = (x) -> Object.prototype.toString.call(x) is '[object Array]'
is_int = (f) -> Math.floor(f) is f
pow2 = (n) -> if n < 31 then (1 << n) else Math.pow(2,n)
twos_comp = (x, n) -> if x < 0 then pow2(n) - Math.abs(x) else x

##=======================================================================

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

  p_byte : (b) -> @_buffer.push_byte twos_comp b, 8
  p_short: (s) -> @_buffer.push_short twos_comp s, 16
  p_int  : (i) -> @_buffer.push_int twos_comp i, 32

  #-----------------------------------------

  #
  # p_neg_int64 -- Pack integer i < -2^31 into a signed quad,
  #   up until the JS resolution cut-off at least.  
  # 
  # The challenge is to express the integer i in the form
  # 2^64 - |i| as per standard 2's complement, and then put both
  # words in the buffer stream.  There's the way it's done:
  #
  #   Given input i, pick x and y such that |i| = 2^32 x + y,
  #   where x,y are both positive, and both less than 2^32.
  #
  #   Now we can write:
  # 
  #       2^64 - |i| = 2^64 - 2^32 x - y
  #
  #   Factoring and rearranging:
  # 
  #       2^64 - |i| = 2^32 * (2^32 - x - 1) + (2^32 - y)
  # 
  #   Thus, we've written:
  #
  #        2^64 - |i| =  2^32 a + b
  #
  #   Where 0 <= a,b < 2^32. In particular:
  #
  #       a = 2^32 - x - 1
  #       b = 2^32 - y
  #
  #   And this satisfies our need to put two positive ints into
  #   stream.
  # 
  p_neg_int64 : (i) ->
    abs_i = 0 - i
    u32max = Math.pow(2,32)
    x = Math.floor( abs_i / u32max)
    y = abs_i & (u32max - 1)
    a = u32max - x - 1
    b = u32max - y
    @p_int a
    @p_int b
   
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
    if i >= -32 then @p_byte i
    else if i >= -128
      @p_byte C.int8
      @p_byte i
    else if i >= -32768
      @p_byte C.int16
      @p_short i
    else if i >= -2147483648
      @p_byte C.int32
      @p_int i
    else
      @p_byte C.int64
      @p_neg_int64 i

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
  
