
##=======================================================================

class CharMap
  constructor : (s) ->
    @fwd = (c for c in s)
    @rev = {}
    @rev[c] = i for c,i in s

##=======================================================================

exports.Buffer = class Buffer

  B16 : new CharMap "0123456789abcdef"
  B32 : new CharMap "abcdefghijkmnpqrstuvwxyz23456789"
  B64 : new CharMap "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

  #-----------------------------------------
  
  constructor : () ->
    @_b = []

  #-----------------------------------------
  
  push_byte   : (b) -> @_b.push b
  push_short  : (s) -> @push_ibytes s, 1
  push_int    : (i) -> @push_ibytes i, 3
  
  #-----------------------------------------
  
  push_bytes  : (a) ->
    for i in [0...a.length]
      @push_byte a.charCodeAt i

  #-----------------------------------------
  
  push_ibytes : (b, n) ->
    @push_byte((b >> (i*8)) & 0xff) for i in [n..0]

  #-----------------------------------------
  
  toString : (enc) ->
    switch enc
      when 'base64' then @base64_encode()
      when 'base32' then @base32_encode()
      when 'hex'    then @base16_encode()
      
  #-----------------------------------------

  _get : (i) -> if i < @_b.length then @_b[i] else 0
   
  #-----------------------------------------

  base16_encode : () ->
    tmp = []
    for c,i in @_b
      tmp[(i << 1)]   = @B16.fwd[(c >> 4)]
      tmp[(i << 1)+1] = @B16.fwd[(c & 0xf)]
    return tmp.join ''
   
  #-----------------------------------------

  base32_encode : () ->
    b = []
    l = @_b.length

    rem = [ 0, 2, 4, 5, 7]
    outlen = Math.floor(l / 5) * 8 + rem[l%5]
    
    for c in [0...l] by 5
      
      # Sum up 40 bits of the string (5 bytes)
      n = 0
      for i in [0..4]
        n += (@_get(c+i) << ((4 - i)*8))
      console.log "n by c: #{n}"

      # push the translation chars onto the b vector
      b.push @B32.fwd[(n >>> i*5) & 0x1f] for i in [7..0]

    console.log "l: #{l}; PL: #{outlen} b.len: #{b.length}"
    return b[0...outlen].join ''
   
  #-----------------------------------------
  
  base64_encode : () ->
    # b = the base array, p = the pad array
    b = []
    l = @_b.length
    
    # Add the pad so that we're a multiple of 3 bytes
    c = l % 3
    p = if c > 0 then ('=' for i in [c...3]) else []

    for c in [0...l] by 3

      # Sum up 24 bits of the string (3-bytes)
      n = (@_get(c) << 16) + (@_get(c+1) << 8) + @_get(c+2)

      # push the translation chars onto the b vector
      b.push @B64.fwd[(n >>> i*6) & 0x3f] for i in [3..0]


    return (b[0...(b.length - p.length)].concat p).join ''

##=======================================================================
