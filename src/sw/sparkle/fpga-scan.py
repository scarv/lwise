# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import driver, itertools

# =============================================================================

def rv32( args ) :
  if ( args.nist ) :
    CONF  = [ 'DRIVER_TEST_BYPASS' ]
    driver.run( args, 'sparkle', CONF, 'rv32', 'nist', NIST_IMP = 'opt' )

  for TYPE in [ 'SPARKLE_RV32_TYPE1', 'SPARKLE_RV32_TYPE2', 'SPARKLE_RV32_TYPE3', 'SPARKLE_RV32_TYPE4' ] :
    CONF  = [ TYPE ]
    CONF += [ 'SPARKLE_RV32_UNROLL' ]
    CONF += [ 'SPARKLE_RV32_ELL'    ]
    CONF += [ 'SPARKLE_RV32_RCON'   ]
    CONF += [ 'DRIVER_TEST_BYPASS'  ]  
    driver.run( args, 'sparkle', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  pass

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
