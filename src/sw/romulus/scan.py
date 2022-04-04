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

    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'ref'            )
    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'opt32t'         )
    driver.run( args, 'romulus', CONF, 'rv32', 'nist', NIST_IMP = 'fixslice_opt32' )

  for TYPE in [ 'ROMULUS_RV32_TYPE1', 'ROMULUS_RV32_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]
      # this flag will not be used in code but can indicate the necessary info to users
      CONF += [ 'ROMULUS_RV32_LUT' ]

      if ( UNROLL ) :
        CONF += [ 'ROMULUS_RV32_UNROLL' ]

      driver.run( args, 'romulus', CONF, 'rv32', 'rv32', NIST_IMP = 'ref'            )

  for TYPE in [ 'ROMULUS_RV32_TYPE1', 'ROMULUS_RV32_TYPE3' ] :
    CONF = [ TYPE ]
    # this flag will not be used in code but can indicate the necessary info to users
    CONF += [ 'ROMULUS_RV32_FIXSLICING' ]
    # there is only unrolled version for fixslicing implementation
    CONF += [ 'ROMULUS_RV32_UNROLL' ]

    driver.run( args, 'romulus', CONF, 'rv32', 'rv32', NIST_IMP = 'fixslice_opt32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'romulus', CONF, 'rv64', 'nist', NIST_IMP = 'ref'            )
    driver.run( args, 'romulus', CONF, 'rv64', 'nist', NIST_IMP = 'opt32t'         )
    driver.run( args, 'romulus', CONF, 'rv64', 'nist', NIST_IMP = 'fixslice_opt32' )

  for TYPE in [ 'ROMULUS_RV64_TYPE1', 'ROMULUS_RV64_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'ROMULUS_RV64_UNROLL' ]

      driver.run( args, 'romulus', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
