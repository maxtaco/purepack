
{pow2,rshift,twos_compl_inv} = require './util'

##=======================================================================

class CharMap
  constructor : (s, pad = "") ->
    @fwd = (c for c in s)
    @rev = {}
    @rev[c] = i for c,i in s
    @rev[c] = 0 for c in pad

##=======================================================================

#
# A base buffer class that's going to be shared between the Node and the
# browser implentation of the Buffer class.
#
exports.PpBuffer = class BaseBuffer

  B16 : new CharMap "0123456789abcdef"
  B32 : new CharMap "abcdefghijkmnpqrstuvwxyz23456789"
  B64 : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "="
  B64X : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@_", "="
  B64A : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-", "="

  #-----------------------------------------
  
  constructor : () ->
    @_e = []
    @_cp = 0
    @_tot = 0

  #-----------------------------------------

  get_errors : () -> if @_e.length then @_e else null

  #-----------------------------------------

  _prepare_encoding : () ->
  
  toString : (enc = 'base64') ->
    @_prepare_encoding()
    switch enc
      when 'buffer'  then @buffer_encode()
      when 'base64'  then @base64_encode()
      when 'base64a' then @base64a_encode()
      when 'base64x' then @base64x_encode()
      when 'base32'  then @base32_encode()
      when 'hex'     then @base16_encode()
      when 'binary'  then @binary_encode()
      when 'ui8a'    then @ui8a_encode()
      
  #-----------------------------------------

  encode : (e) -> @toString e

  #-----------------------------------------

  _get : (i, n) -> throw new Error "pure virtual method"
     
  #-----------------------------------------

  ui8a_encode : () ->
    hold = @_cp
    @_cp = 0
    raw = @read_byte_array @_tot
    @_cp = hold
    raw

  buffer_encode : () -> @ui8a_encode()
  
  #-----------------------------------------

  binary_encode : () ->
    v = (@_get i for i in [0...@_tot])
    String.fromCharCode v...
   
  #-----------------------------------------

  base16_encode : () ->
    tmp = "" 
    for i in [0...@_tot]
      c = @_get i
      tmp += @B16.fwd[(c >> 4)]
      tmp += @B16.fwd[(c & 0xf)]
    tmp
   
  #-----------------------------------------

  bytes_left : () -> @_tot - @_cp

  #-----------------------------------------

  base32_encode : () ->
    # Taken from okws/sfslite armor.C / armor32()
    
    b = []
    l = @_tot

    outlen = Math.floor(l / 5) * 8 + [0,2,4,5,7][l%5]

    p = 0
    for c in [0...l] by 5
      b[p++] = @B32.fwd[@_get(c) >> 3]
      b[p++] = @B32.fwd[(@_get(c) & 0x7) << 2 | @_get(++c) >> 6] if p < outlen
      b[p++] = @B32.fwd[@_get(c) >> 1 & 0x1f]                    if p < outlen
      b[p++] = @B32.fwd[(@_get(c) & 0x1) << 4 | @_get(++c) >> 4] if p < outlen
      b[p++] = @B32.fwd[(@_get(c) & 0xf) << 1 | @_get(++c) >> 7] if p < outlen
      b[p++] = @B32.fwd[@_get(c) >> 2 & 0x1f]                    if p < outlen
      b[p++] = @B32.fwd[(@_get(c) & 0x3) << 3 | @_get(++c) >> 5] if p < outlen
      b[p++] = @B32.fwd[@_get(c) & 0x1f]                         if p < outlen
      
    return b[0...outlen].join ''
   
  #-----------------------------------------

  base64_encode :  () -> @_base64_encode @B64
  base64a_encode : () -> @_base64_encode @B64A
  base64x_encode : () -> @_base64_encode @B64X
  
  #-----------------------------------------
  
  _base64_encode : (M) ->
    # b = the base array, p = the pad array
    b = []
    l = @_tot
    
    # Add the pad so that we're a multiple of 3 bytes
    c = l % 3
    p = if c > 0 then ('=' for i in [c...3]) else []

    for c in [0...l] by 3

      # Sum up 24 bits of the string (3-bytes)
      n = (@_get(c) << 16) + (@_get(c+1) << 8) + @_get(c+2)

      # push the translation chars onto the b vector
      b.push M.fwd[(n >>> i*6) & 0x3f] for i in [3..0]

    return (b[0...(b.length - p.length)].concat p).join ''

  #-----------------------------------------

  @_decode : (klass, s, enc) ->
    obj = new klass
    if not enc? and typeof(s) is 'string'
      obj.base64_decode s
    else 
      switch enc
        when 'buffer'  then obj.buffer_decode s
        when 'binary'  then obj.binary_decode s
        when 'base64'  then obj.base64_decode s
        when 'base64a' then obj.base64a_decode s
        when 'base64x' then obj.base64x_decode s
        when 'base32'  then obj.base32_decode s
        when 'hex'     then obj.base16_decode s
        when 'ui8a'    then obj.ui8a_decode s
        else  null
     
  #-----------------------------------------

  buffer_decode : (s) -> @ui8a_decode s
  
  #-----------------------------------------
  
  binary_decode : (b) ->
    (@push_uint8 b.charCodeAt i for i in [0...b.length])
    @
    
  #-----------------------------------------

  base16_decode : (data) ->
    if (data.length % 2) isnt 0 then null
    else
      last = 0
      for c,i in data
        return null if not (v = @B16.rev[c])?
        if i % 2 is 0 then last = v
        else @push_uint8 ((last << 4) | v)
      @
     
  #-----------------------------------------

  _base64_decode : (data, M) ->
    if (data.length % 4) isnt 0 then null
    else
      sum = 0
      npad = 0
      for c,i in data
        return null unless (v = M.rev[c])?
        npad++ if c is '='
        sum = ((sum << 6) | v)
        if i % 4 is 3
          @push_uint8((sum >> i*8) & 0xff) for i in [2..npad]
          sum = 0
      @
      
  #-----------------------------------------
  
  base64_decode  : (data) -> @_base64_decode data, @B64
  base64a_decode : (data) -> @_base64_decode data, @B64A
  base64x_decode : (data) -> @_base64_decode data, @B64X
 
  #-----------------------------------------

  base32_decode : (data) ->
    sum = 0
    
    for c, i in data
      return null unless (v = @B32.rev[c])?

      # We can't use bitwise right shift here (or bitwise OR)
      # since that will break when we're above 32 bits.  Of course
      # we have a 40-bit window for base32-encodings.
      before = sum
      sum = (sum * 32) + v
      
      if i % 8 is 7
        
        # Again, we don't use '>>' but instead 'rshift', which
        # can handle numbers above 2^32.
        @push_uint8(rshift(sum,j*8) & 0xff) for j in [4..0]

        # clear out the sum for the next time through the loop
        sum = 0

    # now we have to futz with the remainder
    if (rem = data.length % 8) isnt 0

      # we still need to shift the currently active sum over
      sum *= 32 for i in [8...rem]

      # Only certain sizes of remainder are admissible, it's the
      # reverse of the above map. 'nmb' = number more bytes.
      return null unless (nmb = {2:1,4:2,5:3,7:4}[rem])?

      # As above, we shift bytes on, starting from the left and
      # marching rightward.  But we stop early.
      @push_uint8(rshift(sum,i*8) & 0xff) for i in [4...(4-nmb)]

    @ # success at last

  #-----------------------------------------

  read_bytes : (n) -> (@read_uint8() for i in [0...n])

##=======================================================================

exports.is_uint8_array = (x) -> 
  Object.prototype.toString.call(x) is '[object Uint8Array]'
  
##=======================================================================
