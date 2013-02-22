
{pow2,rshift} = require './util'

##=======================================================================

class CharMap
  constructor : (s, pad = "") ->
    @fwd = (c for c in s)
    @rev = {}
    @rev[c] = i for c,i in s
    @rev[c] = 0 for c in pad

##=======================================================================

#
# This buffer is made up of a chain of Uint8Arrays, each of fixed size.
# This is a good performance boost over a standard array, but of course
# we can't push() onto it...
# 
exports.Buffer = class Buffer

  B16 : new CharMap "0123456789abcdef"
  B32 : new CharMap "abcdefghijkmnpqrstuvwxyz23456789"
  B64 : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "="
  B64X : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@_", "="
  B64A : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-", "="

  #-----------------------------------------
  
  constructor : () ->
    @_buffers = []
    @_sz = 0x400
    @_logsz = 10
    @_push_new_buffer()
    @_i = 0
    @_b = 0
    @_cp = 0
    @_tot = 0
    @_no_push = false

  #-----------------------------------------
  
  _push_new_buffer : () ->
    @_b = @_buffers.length
    @_i = 0
    nb = new Uint8Array @_sz
    @_buffers.push nb
    nb

  #-----------------------------------------
   
  push_byte   : (b) ->
    throw new Error "Cannot push anymore into this buffer" if @_no_push
    buf = @_buffers[@_b]
    (buf = @_push_new_buffer()) if @_i is @_sz
    buf[@_i++] = b
    @_tot++
  
  #-----------------------------------------
  
  push_short  : (s) -> @push_ibytes s, 1
  push_int    : (i) -> @push_ibytes i, 3
  
  #-----------------------------------------

  push_buffer : (b) ->
    for i in [0...b.length]
      @push_byte b[i]
    @
   
  #-----------------------------------------
  
  push_bytes  : (a) ->
    for i in [0...a.length]
      @push_byte a.charCodeAt i
    @

  #-----------------------------------------
  
  push_ibytes : (b, n) ->
    @push_byte((b >> (i*8)) & 0xff) for i in [n..0]

  #-----------------------------------------
  
  toString : (enc = 'base64') ->
    switch enc
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

  bytes_left : () -> @_tot - @_cp

  #-----------------------------------------

  # Get n characters starting at index i.
  # If n is null, then assume just 1 character and return
  # as a scalar.  Otherwise, return as a list of chars.
  _get : (i, n = null) ->
    zero_pad = if n? then ( 0 for j in [0...n] ) else 0
    ret = if i >= @_tot then zero_pad
    else
      bi = if @_logsz then (i >>> @_logsz) else 0 # buffer index
      li = i % @_sz                               # local index
      lim = if bi is @_b then @_i else @_sz       # local limit

      ret = if bi > @_b or li >= lim then zero_pad
      else if not n? then @_buffers[bi][li]
      else
        n = Math.min( lim - li, n )
        @_buffers[bi].subarray(li, (li+n))
    ret
   
  #-----------------------------------------

  ui8a_encode : () ->
    out = new Uint8Array @_tot
    (out[i] = @_get i for i in [0...@_tot])
    out
  
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

  @decode : (s, enc) ->
    switch enc
      when 'binary'  then (new Buffer).binary_decode s
      when 'base64'  then (new Buffer).base64_decode s
      when 'base64a' then (new Buffer).base64a_decode s
      when 'base64x' then (new Buffer).base64x_decode s
      when 'base32'  then (new Buffer).base32_decode s
      when 'hex'     then (new Buffer).base16_decode s
      when 'ui8a'    then (new Buffer).ui8a_decode s
     
  #-----------------------------------------

  # Just call the given array the whole thing, and give up on
  # 2d-indexing. Once you do this, you can't push anymore bytes on
  ui8a_decode : (v) ->
    @_buffers = [ v ]
    @_logsz = 0
    @_tot = @_sz = @_i = v.length
    @_no_push = true
    @

  #-----------------------------------------
  
  binary_decode : (b) ->
    (@push_byte b.charCodeAt i for i in [0...b.length])
    @
    
  #-----------------------------------------

  base16_decode : (data) ->
    if (data.length % 2) isnt 0 then null
    else
      last = 0
      for c,i in data
        return null if not (v = @B16.rev[c])?
        if i % 2 is 0 then last = v
        else @push_byte ((last << 4) | v)
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
          @push_byte((sum >> i*8) & 0xff) for i in [2..npad]
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
        @push_byte(rshift(sum,j*8) & 0xff) for j in [4..0]

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
      @push_byte(rshift(sum,i*8) & 0xff) for i in [4...(4-nmb)]

    @ # success at last

  #-----------------------------------------

  consume_byte : () -> @_get @_cp++
  
  #-----------------------------------------

  consume_bytes : (n) -> (@consume_byte() for i in [0...n])

  #-----------------------------------------

  consume_chunk : (n) ->
    ret = @_get @_cp, n
    @_cp += ret.length
    ret

  #-----------------------------------------

  # Consume a string of n bytes, in 2K chunks.
  # Still need to call String.fromCharCode on them
  # in a pretty awkward way.  Maybe we should look for
  # alternatives....
  consume_string : (n) ->
    i = 0
    chunksz = 0x800
    bl = @bytes_left()
    if n > bl
      console.log "Corruption: asked for #{n} bytes, but only #{bl} available"
      n = bl
    parts = while i < n
      s = Math.min( n - i, chunksz )
      chnk = @consume_chunk s
      i += chnk.length
      String.fromCharCode chnk...
    parts.join ''
   
  #-----------------------------------------
  
        
##=======================================================================
