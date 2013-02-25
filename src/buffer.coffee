
{pow2,rshift,twos_compl_inv} = require './util'

##=======================================================================

class CharMap
  constructor : (s, pad = "") ->
    @fwd = (c for c in s)
    @rev = {}
    @rev[c] = i for c,i in s
    @rev[c] = 0 for c in pad

##=======================================================================

NodeBuffer = Buffer

#
# This buffer is made up of a chain of Uint8Arrays, each of fixed size.
# This is a good performance boost over a standard array, but of course
# we can't push() onto it...
# 
exports.Buffer = class MyBuffer

  B16 : new CharMap "0123456789abcdef"
  B32 : new CharMap "abcdefghijkmnpqrstuvwxyz23456789"
  B64 : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "="
  B64X : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@_", "="
  B64A : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-", "="

  #-----------------------------------------
  
  constructor : () ->
    @_buffers = []
    @_sz = 0x1000
    @_logsz = 12
    @_push_new_buffer()
    @_i = 0
    @_b = 0
    @_cp = 0
    @_tot = 0
    @_no_push = false
    @_e = []

  #-----------------------------------------

  get_errors : () -> if @_e.length then @_e else null

  #-----------------------------------------
  
  _push_new_buffer : () ->
    @_b = @_buffers.length
    @_i = 0
    nb = new Uint8Array @_sz
    @_buffers.push nb
    nb

  #-----------------------------------------

  _left_in_buffer : () -> (@_sz - @_i)

  #-----------------------------------------
   
  push_byte   : (b) ->
    throw new Error "Cannot push anymore into this buffer" if @_no_push
    buf = @_buffers[@_b]
    (buf = @_push_new_buffer()) if @_i is @_sz
    buf[@_i++] = b
    @_tot++
  
  #-----------------------------------------
  
  # unroll the obvious loop for performance...
  push_short  : (i) -> 
    @push_byte((i >> 8) & 0xff)
    @push_byte(i & 0xff)

  # unroll the obvious loop for performance...
  push_int    : (i) ->
    @push_byte((i >> 24) & 0xff)
    @push_byte((i >> 16) & 0xff)
    @push_byte((i >> 8) & 0xff)
    @push_byte(i & 0xff)
  
  #-----------------------------------------

  push_raw_bytes : (s) ->
    a = new Uint8Array(s.length)
    for i in [0...s.length]
      a[i] = s.charCodeAt i
    @push_buffer a

  #-----------------------------------------

  push_buffer : (input) ->
    bp = 0
    ep = input.length
    while bp < ep
      lib = @_left_in_buffer()
      if lib is 0
        slab = @_push_new_buffer()
        lib = @_left_in_buffer()
      else
        slab = @_buffers[@_b]
      n = Math.min(lib, ep - bp)
      slab.set(input.subarray(bp, bp+n), @_i)
      @_i += n
      @_tot += n
      bp += n
    @

  #-----------------------------------------

  # This code isn't being used, but ;et's keep it in for now...
  push_utf8_codepoint : (c) ->
    if c >= 0x10000
      @push_byte( 0xf0 | ((c & 0x1c0000) >>> 18))
      @push_byte( 0x80 | ((c & 0x3f000 ) >> 12 ))
      @push_byte( 0x80 | ((c & 0xfc0   ) >>> 6))
      @push_byte( 0x80 | ( c & 0x3f    ))
    else if c >= 0x800
      @push_byte( 0xe0 | ((c & 0xf000  ) >>> 12))
      @push_byte( 0x80 | ((c & 0xfc0   ) >> 6))
      @push_byte( 0x80 | ( c & 0x3f    ))
    else if c >= 0x80 
      @push_byte( 0xc0 | ((c & 0x7c0   ) >>> 6))
      @push_byte( 0x80 | ( c & 0x3f    ))
    else
      @push_byte c

  #-----------------------------------------

  push_utf8_string : (s) ->
    for i in [0...s.length]
      cc = s.charCodeAt i
      @push_utf8_codepoint cc
    @

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
  # Might return fewer than n bytes!
  _get : (i, n = null) ->
    zero_pad = if n? then ( 0 for j in [0...n] ) else 0
    ret = if i >= @_tot then zero_pad
    else
      bi = if @_logsz then (i >>> @_logsz) else 0 # buffer index
      li = i % @_sz                               # local index
      lim = if bi is @_b then @_i else @_sz       # local limit

      ret = if bi > @_b or li >= lim then zero_pad
      else if not n? 
        c = @_buffers[bi][li]
        c
      else
        n = Math.min( lim - li, n )
        @_buffers[bi].subarray(li, (li+n))
    ret
   
  #-----------------------------------------

  ui8a_encode : () ->
    hold = @_cp
    @_cp = 0
    raw = @read_byte_array @_tot
    @_cp = hold
    raw
  
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
      when 'binary'  then (new MyBuffer).binary_decode s
      when 'base64'  then (new MyBuffer).base64_decode s
      when 'base64a' then (new MyBuffer).base64a_decode s
      when 'base64x' then (new MyBuffer).base64x_decode s
      when 'base32'  then (new MyBuffer).base32_decode s
      when 'hex'     then (new MyBuffer).base16_decode s
      when 'ui8a'    then (new MyBuffer).ui8a_decode s
     
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

  read_bytes : (n) -> (@read_uint8() for i in [0...n])

  #-----------------------------------------

  read_uint8  : () -> @_get @_cp++
  read_uint16 : () ->
    (@read_uint8() << 8) | @read_uint8()
  read_uint32 : () ->
    ((@read_uint8()*pow2(24)) + ((@read_uint8() << 16) | (@read_uint8() << 8 ) | @read_uint8()))

  read_int8  : () -> twos_compl_inv @read_uint8(),  8
  read_int16 : () -> twos_compl_inv @read_uint16(), 16
  read_int32 : () -> twos_compl_inv @read_uint32(), 32

  #-----------------------------------------

  read_double : () -> @_read_float 8
  read_float  : () -> @_read_float 4

  #-----------------------------------------

  _read_float : (nb) -> 
    a = @read_byte_array nb
    dv = new DataView a
    dv["getFloat#{nb << 3}"].call dv, 0, false

  #-----------------------------------------

  # Read n or fewer bytes from the buffer
  read_chunk : (n) ->
    ret = @_get @_cp, n
    @_cp += ret.length
    ret

  #-----------------------------------------

  # read exactly n bytes from the buffer
  read_byte_array : (n) ->
    i = 0

    ret = null
    n = @prep_byte_grab n

    # Simplify the (hopefully) common case which is that
    # _read_chunk() pulled us exactly as much data as we 
    # needed....
    chnk = @read_chunk n
    if chnk.length is n
      ret = chnk
    else
      # This is the disappointing case, in which we have
      # to build this array up from multiple arrays.
      ret = new Uint8Array(n)
      ret.set chnk, 0
      i = chnk.length
      while i < n
        chnk = @read_chunk(n-i)
        ret.set chnk, i
        i += chnk.length
    return ret
   
  #-----------------------------------------

  prep_byte_grab : (n) ->
    bl = @bytes_left()
    if n > bl
      @_e.push "Corruption: asked for #{n} bytes, but only #{bl} available"
      n = bl
    return n
  
  #-----------------------------------------

  read_utf8_string : (n) ->
    i = 0
    n = @prep_byte_grab n
    chnksz = 0x400
    tmp = while i < n
      s = Math.min n-i, chnksz
      chnk = @read_chunk s
      i += chnk.length
      encode_chunk chnk
    try
      ret = decodeURIComponent tmp.join ''
    catch e
      @_e.push "Invalid UTF-8 sequence"
      ret = ""
    ret

  # Covert a javascript UTF-8 string to a Uint8Array of the character-by-character
  # encodings.  I wish there were a fast, clean way to do this.  We could
  # also write the encoder by hand, but if we did, we couldn't use 
  # String.fromCharCode, since that doesn't work over codepoints with values 
  # over 0x10000.
  #
  #  In node, we could do something like this:
  #
  #      new Uint8Array( new NodeBuffer s, 'utf8' )
  #
  # While way faster than way we're currently doing, it's still much slower than
  # just manipulating buffers directly.
  #
  @utf8_to_ui8a : (s) ->
    s = encodeURIComponent s
    n = s.length
    ret = new Uint8Array s.length
    rp = 0
    i = 0
    while i < n
      c = s[i]
      if c is '%'
        c = parseInt s[(i+1)..(i+2)], 16
        i += 3
      else 
        c = c.charCodeAt 0
        i++
      ret[rp++] = c
    ret.subarray(0,rp)

  #-----------------------------------------
  
  @ui8a_to_binary : (b) ->
    chnksz = 0x100
    n = b.length
    i = 0
    parts = []
    while i < n
      s = Math.min(n-i,chnksz)  
      parts.push String.fromCharCode b.subarray(i,i+s)...
      i += n
    parts.join ''

##=======================================================================

# Stop at the first non-ascii character, or at a %,
# which needs to be encoded too...
first_non_ascii = (chunk, start, end) ->
  for i in [start...end]
    return i if chunk[i] >= 0x80 or chunk[i] is 0x25
  return end

encode_byte = (b) ->
  ub = ((b >>> 4) & 0xf).toString(16)
  lb = (b & 0xf).toString(16)
  "%#{ub}#{lb}"

encode_chunk = (chunk) ->
  n = chunk.length
  i = 0
  parts = while i < n
    fna = first_non_ascii chunk, i, n
    if fna > i
      sa = chunk.subarray i, fna
      i = fna
      String.fromCharCode sa...
    else
      encode_byte chunk[i++]
  out = parts.join ''
  return out
