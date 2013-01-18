
ab = new ArrayBuffer n
ia = new Uint8Array ab

ia[0] = 10
ia[1] = 244
ia[2] = 30
ia[3] = 30

dv = new DataView ab

offset = 0
little_endian = 0
dv.getFloat32 offset, little_endian
