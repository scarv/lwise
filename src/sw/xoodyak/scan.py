# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import driver, itertools

# =============================================================================

def rv32( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'xoodyak', CONF, 'rv32', 'nist', NIST_IMP = 'ref' )

  for TYPE in [ 'XOODYAK_RV32_TYPE1', 'XOODYAK_RV32_TYPE2' ] :
    # for UNROLL in [ False, True ] :
    for ZBKB_ZBKX in [ False, True ] :    
      # CONF = [ TYPE, 'ENABLE_ZBKB_ZBKX' ]
      CONF = [ TYPE ]

      # if ( UNROLL ) :
      #   CONF += [ 'XOODYAK_UNROLL' ]
      if ( ZBKB_ZBKX ):
        CONF += [ 'ENABLE_ZBKB_ZBKX' ]        
  
      driver.run( args, 'xoodyak', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'xoodyak', CONF, 'rv64', 'nist', NIST_IMP = 'ref' )

  # for TYPE in [ 'XOODYAK_RV64_TYPE1', 'XOODYAK_RV64_TYPE2' ] :
  for TYPE in [ 'XOODYAK_RV64_TYPE1' ] :
    # for UNROLL in [ False, True ] :
    for ZBKB_ZBKX in [ False, True ] :  
      # CONF = [ TYPE, 'ENABLE_ZBKB_ZBKX' ]
      CONF = [ TYPE ]

      # if ( UNROLL ) :
      #   CONF += [ 'XOODYAK_UNROLL' ]
      if ( ZBKB_ZBKX ):
        CONF += [ 'ENABLE_ZBKB_ZBKX' ]   
  
      driver.run( args, 'xoodyak', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
