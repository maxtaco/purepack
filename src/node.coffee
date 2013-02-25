
BaseBuffer = require('./base').Buffer

##=======================================================================

exports.Buffer = class NodeBuffer extends BaseBuffer

  #-----------------------------------------

  constructor : () ->
    super()
    @_buffers = []
    @_limits = []
    @_cumsum = [ 0 ]
    @_sz = 0x1000
    @_logsz = 12
    @_i = 0
    @_no_push = false
    @_tot = 0
    @_push_new_buffer()
    @_last_bi = null
    @_cp = 0

  #-----------------------------------------

  @decode = (s, enc) -> BaseBuffer._decode NodeBuffer, s, enc

  #-----------------------------------------

  _nb  : () -> @_buffers.length     # num buffers
  _ab  : () -> @_buffers[@_nb()]    # active buffer
  _lib : () -> @_sz - @_i           # left in buffer

  #-----------------------------------------

  _push_buffer : (b) ->
    nb = @_nb()
    @_limits[nb] = @_i
    @_cumsum[nb] = @_cumsum[nb-1] + @_i if nb > 0
    @_i = 0
    @_buffers.push b
    b

  #-----------------------------------------

  _push_new_buffer : () -> @_push_buffer new Buffer @_sz

  #-----------------------------------------
  
  push_uint8 : (b) ->
    throw new Error "Cannot push anymore into this buffer" if @_no_push
    buf = if @_lib() is 0 then @_push_new_buffer() else @_ab()
    buf[@_i++] = @_b
    @_tot++

  push_int8 : (b) -> @push_uint8 b

  push_uint16 : (s) -> 
    n = 2
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint16BE s, @_i
    @_i += n
    @_tot += n

  push_uint32 : (i) ->
    n = 4
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint32BE s, @_i
    @_i += n
    @_tot += n

  push_int16 : (s) -> 
    n = 2
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeInt16BE s, @_i
    @_i += n
    @_tot += n

  push_int32 : (i) ->
    n = 4
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeInt32BE s, @_i
    @_i += n
    @_tot += n

  push_raw_bytes : (s) ->
    @push_buffer new Buffer s, 'binary'

  push_buffer : (b) ->
    if b.length > Math.min(0x400, @_sz)
      @_push_buffer b
      @_push_new_buffer()
    else
      n = Math.min b.length, @_lib()
      b.copy @_ab(), @_i, 0, n
      @_i += n
      @_tot += n
      if n < b.length
        @_push_new_buffer()
        b.copy @_ab(), @_i, n, b.length
        diff = b.length - n
        @_i += diff
        @_tot += diff

  #-----------------------------------------

  # map the given offset to a sub-buffer; optimization: we're usually
  # going to pick up where we left off, so assume that going forward.
  # hence the @_last_bi variable
  _get_sub_buffer : (index) ->
    if n >= @_tot then return null

    bi = if @_last_bi? and index >= @_cumsum[@_last_bi] then @_last_bi
    else 0

    nb = @_nb()
    while bi < nb
      if index < @_cumsum[bi+1] then break
      else bi++
    @_last_bi = bi

    [ @_buffers[bi],                              # the buffer
      (offset - @_cumsum[bi]),                    # the offset in that buffer
      (if bi is nb then @_i else @_limits[bi]) ]  # last offset in that buffer

  #-----------------------------------------

  _zero_pad : (n) -> if n? then ( 0 for j in [0...n] ) else 0

  # Get n characters starting at index i.
  # If n is null, then assume just 1 character and return
  # as a scalar.  Otherwise, return as a list of chars.
  # Might return fewer than n bytes!
  _get : (i, n = null) ->
    if i >= @_tot then @_zero_pad n
    else
      [ buf, i, lim ] = @_get_sub_buffer i
      if n? then buf[i...(Math.min(lim,i+n))]
      else       buf[i]

  #-----------------------------------------

  # same as in Browser's buffer
  ui8a_decode : (v) ->
    @_buffers = [ new Buffer v ]
    @_logsz = 0
    @_tot = @_sz = @_i = v.length
    @_no_push = true
    @

  #-----------------------------------------

  read_uint8 : () -> @_get @_cp++

