
##=======================================================================

exports.Buffer = class Buffer

  #-----------------------------------------
  
  constructor : () ->
    @_b = []
    @init_base64_map()

  #-----------------------------------------
  
  init_base64_map : () ->
    c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    @_b64_map = []
    for i in [0...c.length]
      @_b64_map.push c.charAt i
  
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
    if enc is 'base64' then @base64_encode()

  #-----------------------------------------

  _get : (i) -> if i < @_b.length then @_b[i] else 0
   
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

      # push the translation chars onto the tmp vector
      b.push @_b64_map[(n >>> i*6) & 0x3f] for i in [3..0]


    return (b[0...(b.length - p.length)].concat p).join ''

##=======================================================================
