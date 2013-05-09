exports.data =  

  s1 : "hello"

  o1 : { hi : "mom", bye : "dad" }

  r1: [-100..100]

  r2: [-1000..1000]

  r3: [-32800...-32700]

  r4: [-2147483668...-2147483628]

  r5: [0xfff0...0x1000f]

  r6: [0xfffffff0...0x10000000f]

  i1: -2147483649

  f1: [ 1.1, 10.1, 20.333, 44.44444, 5.555555]

  f2: [ -1.1, -10.1, -20.333, -44.44444, -5.555555]

  o2: 
    foo : [0..10]
    bar :
      bizzle : null
      jam : true
      jim : false
      jupiter : "abc ABC 123"
      saturn : 6
    bam :
      boom :
        yam :
          potato : [10..20]

  o3:
    notes : null
    algo_version : 3
    generation : 1
    email : "themax@gmail.com"
    length : 12
    num_symbols : 0
    security_bits : 8 

  s2: "themax@gmail.com"

  u1: {}.yuck

  s3: (i for i in [1...100]).join ' '

  o4 : obj : (i for i in [1...100]).join ' '

  o5: 
    email : "themax@gmail.com"
    notes : "not active yet, still using old medium security. update this note when fixed."
    algo_version : 3,
    length : 12
    num_symbols : 0
    generation : 1
    security_bits : 8
