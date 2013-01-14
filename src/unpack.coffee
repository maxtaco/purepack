
{C} = require './const'
{Buffer} = require './buffer'
{twos_compl_inv} = require './util'
  

##=======================================================================

exports.Unpacker = class Unpacker

  constructor : ()  ->
    @_buffer = null
    @_e = []
    
  #-----------------------------------------
  
  decode : (s, enc) -> return !! (@_buffer = Buffer.decode s, enc)

  #-----------------------------------------

  error : (e) ->
    @_e.push e
    null
   
  #-----------------------------------------

  u : () ->
    b = @_buffer.get_byte()
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
