
{pow2,rshift,twos_compl_inv} = require './util'
BaseBuffer = require('./buffer').Buffer

##=======================================================================

#
# This buffer is made up of a chain of Uint8Arrays, each of fixed size.
# This is a good performance boost over a standard array, but of course
# we can't push() onto it...
# 
exports.Buffer = class BrowserBuffer extends BaseBuffer

  #-----------------------------------------
  
  constructor : () ->
    super()
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

  push_utf8_string : (s) ->
    for i in [0...s.length]
      cc = s.charCodeAt i
      @push_utf8_codepoint cc
    @

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

  # Just call the given array the whole thing, and give up on
  # 2d-indexing. Once you do this, you can't push anymore bytes on
  ui8a_decode : (v) ->
    @_buffers = [ v ]
    @_logsz = 0
    @_tot = @_sz = @_i = v.length
    @_no_push = true
    @


  #-----------------------------------------

  read_uint8  : () -> @_get @_cp++
  read_uint16 : () ->
    (@read_uint8() << 8) | @read_uint8()

  # note this subtlety --- any bitwise math over 31 bits will flip a signed bit,
  # so we need to + and * when we get close. In the lower regions, we should be OK
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
      uri_encode_chunk chnk
    try
      ret = decodeURIComponent tmp.join ''
    catch e
      @_e.push "Invalid UTF-8 sequence"
      ret = ""
    ret

  #-----------------------------------------

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

#
# Hacks for minimally URI-encoding a string, so we can URI-decode it right
# away.  This is horrible but I think it's the fastest way to convert binary
# to a UTF-8 string on the browser...
#
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

uri_encode_chunk = (chunk) ->
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

##=======================================================================
