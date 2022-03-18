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

    driver.run( args, 'jambu', CONF, 'rv32', 'nist', NIST_IMP = 'ref' )
    driver.run( args, 'jambu', CONF, 'rv32', 'nist', NIST_IMP = 'opt' )

  for TYPE in [ 'JAMBU_RV32_TYPE1', 'JAMBU_RV32_TYPE2', 'JAMBU_RV32_TYPE3' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'JAMBU_RV32_UNROLL' ]

      driver.run( args, 'jambu', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'jambu', CONF, 'rv64', 'nist', NIST_IMP = 'ref' )
    driver.run( args, 'jambu', CONF, 'rv64', 'nist', NIST_IMP = 'opt' )

  for TYPE in [ 'JAMBU_RV64_TYPE1', 'JAMBU_RV64_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'JAMBU_RV64_UNROLL' ]
  
      driver.run( args, 'jambu', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
