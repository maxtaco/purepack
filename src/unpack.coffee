
{C} = require './const'
{Buffer} = require './buffer'
{twos_compl_inv,U32MAX,u64max_minus_i} = require './util'
  

##=======================================================================

exports.Unpacker = class Unpacker

  constructor : ()  ->
    @_buffer = null
    @_e = []
    
  #-----------------------------------------
  
  decode : (s, enc) -> return !! (@_buffer = Buffer.decode s, enc)

  #-----------------------------------------

  u_raw : (n) -> @_buffer.consume_string n
   
  #-----------------------------------------

  u_array : (n) -> (@u() for i in [0...n])
   
  #-----------------------------------------

  u_map : (n) ->
    ret = {}
    for i in [0...n]
      ret[@u()] = @u()
    return ret
     
  #-----------------------------------------

  u_uint8 = () -> @_buffer.consume_byte()
  u_int8 = () -> twos_compl_inv @u_uint8()
  u_uint16 = () ->
    v = @_buffer.consume_bytes 2
    return (v[0] << 8 | v[1])
  u_int16 = () -> twos_compl_inv @u_int16()
  u_uint32 = () ->
    v = @_buffer.consume_bytes 4
    return ((v[0] << 24) | (v[1] << 16) | (v[2] << 8) | v[3])
  u_int32 = () -> return twos_compl_inv @u_uint32
  u_uint64 = () -> (@u_uint32() * U32MAX) + @u_uint32()
  u_int64 = () ->
    [a,b] = u64max_minus_i @u_uint64()
    return -1 * a * U32MAX - b
    
  #-----------------------------------------

  error : (e) ->
    @_e.push e
    null
   
  #-----------------------------------------

  u : () ->
    b = @_buffer.consume_byte()
    if b <= C.positive_fix_max then b
    else if b >= C.negative_fix_min and b <= C.negative_fix_max
      twos_compl_inv b, 8
    else if b >= C.fix_raw_min and b <= C.fix_raw_max
      l = (b & C.fix_raw_count_mask)
      @u_raw l
    else if b >= C.fix_array_min and b <= C.fix_array_max
      l = (b & C.fix_array_count_mask)
      @u_array l
    else if b >= C.fix_map_min and b <= C.fix_map_max
      l = (b & C.fix_map_count_mask)
      @u_map l
    else
      switch b
        when C.null  then null
        when C.true  then true
        when C.false then false
        when C.uint8 then @u_uint8()
        when C.uint16 then @u_uint16()
        when C.uint32 then @u_uint32()
        when C.uint64 then @u_uint64()
        when C.int8 then @u_int8()
        when C.int16 then @u_int16()
        when C.int32 then @u_int32()
        when C.int64 then @u_int64()
        when C.double then @u_double()
        when C.float then @u_float()
        when C.raw16 then @u_raw @u_uint16()
        when C.raw32 then @u_raw @u_uint32()
        when C.array16 then @u_array @u_uint16()
        when C.array32 then @u_array @u_uint32()
        when C.map16 then @u_map @u_uint16()
        when C.map32 then @u_map @u_uint32()
        else @error "unhandled type #{b}"
      
  #-----------------------------------------

      

##=======================================================================

exports.unpack = (x) -> null
