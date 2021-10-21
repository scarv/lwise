#include    "zbkb.h"
#include    "zbkx.h"

.text

.global test_ror
.func   test_ror
test_ror:
    ror a0, a0, a1
    ret
.endfunc
	
.global test_rol
.func   test_rol
test_rol:
    rol a0, a0, a1
    ret
.endfunc

.global test_ror7
.func   test_ror7
test_ror7:
    rori a0, a0, 7
    ret
.endfunc

.global test_andn
.func   test_andn
test_andn:
    andn a0, a0, a1
    ret
.endfunc

.global test_orn
.func   test_orn
test_orn:
    orn a0, a0, a1
    ret
.endfunc

.global test_xnor
.func   test_xnor
test_xnor:
    xnor a0, a0, a1
    ret
.endfunc

.global test_pack
.func   test_pack
test_pack:
    pack a0, a0, a1
    ret
.endfunc

.global test_packh
.func   test_packh
test_packh:
    packh a0, a0, a1
    ret
.endfunc

.global test_brev8
.func   test_brev8
test_brev8:
    brev8 a0, a0
    ret
.endfunc

.global test_rev8
.func   test_rev8
test_rev8:
    rev8 a0, a0
    ret
.endfunc

.global test_zip
.func   test_zip
test_zip:
    zip a0, a0
    ret
.endfunc

.global test_unzip
.func   test_unzip
test_unzip:
    unzip a0, a0
    ret
.endfunc

.global test_xperm8
.func   test_xperm8
test_xperm8:
    xperm8 a0, a0, a1
    ret
.endfunc

.global test_xperm4
.func   test_xperm4
test_xperm4:
    xperm4 a0, a0,a1
    ret
.endfunc
