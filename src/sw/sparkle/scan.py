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

    driver.run( args, 'sparkle', CONF, 'rv32', 'nist', NIST_IMP = 'ref' )
    driver.run( args, 'sparkle', CONF, 'rv32', 'nist', NIST_IMP = 'opt' )

  for TYPE in [ 'SPARKLE_RV32_TYPE1', 'SPARKLE_RV32_TYPE2', 'SPARKLE_RV32_TYPE3', 'SPARKLE_RV32_TYPE4'                       ] :
    for UNROLL in [ False, True ] :
      for ( ELL, RCON ) in itertools.product( [ False, True ], repeat = 2 ) :
        CONF = [ TYPE ]

        if ( UNROLL ) :
          CONF += [ 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'SPARKLE_REV_UNROLL' ]
        if ( ELL    ) :
          CONF += [ 'SPARKLE_RV32_ELL'   ]
        if ( RCON   ) :
          CONF += [ 'SPARKLE_RV32_RCON'  ]
  
        driver.run( args, 'sparkle', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'sparkle', CONF, 'rv64', 'nist', NIST_IMP = 'ref' )
    driver.run( args, 'sparkle', CONF, 'rv64', 'nist', NIST_IMP = 'opt' )

  for TYPE in [ 'SPARKLE_RV64_TYPE1', 'SPARKLE_RV64_TYPE2', 'SPARKLE_RV64_TYPE3', 'SPARKLE_RV64_TYPE4', 'SPARKLE_RV64_TYPE5' ] :
    for UNROLL in [ False, True ] :
      for ( ELL, RCON ) in itertools.product( [ False, True ], repeat = 2 ) :
        CONF = [ TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'SPARKLE_REV_UNROLL' ]
        if ( ELL      ) :
          CONF += [ 'SPARKLE_RV64_ELL'   ]
        if ( RCON     ) :
          CONF += [ 'SPARKLE_RV64_RCON'  ]

        driver.run( args, 'sparkle', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
