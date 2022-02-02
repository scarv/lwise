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

    driver.run( args, 'grain', CONF, 'rv32', 'nist', NIST_IMP = 'ref' )

  for TYPE in [ 'GRAIN_RV32_TYPE1', 'GRAIN_RV32_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'GRAIN_UNROLL' ]
  
      driver.run( args, 'grain', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'grain', CONF, 'rv64', 'nist', NIST_IMP = 'ref' )
    driver.run( args, 'grain', CONF, 'rv64', 'nist', NIST_IMP = 'x64' )

  for TYPE in [ 'GRAIN_RV64_TYPE1', 'GRAIN_RV64_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'GRAIN_UNROLL' ]
  
      driver.run( args, 'grain', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
