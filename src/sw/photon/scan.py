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

    driver.run( args, 'photon', CONF, 'rv32', 'nist', NIST_IMP = 'ref'           )
    driver.run( args, 'photon', CONF, 'rv32', 'nist', NIST_IMP = 'table2'        )
    driver.run( args, 'photon', CONF, 'rv32', 'nist', NIST_IMP = 'table3'        )
    driver.run( args, 'photon', CONF, 'rv32', 'nist', NIST_IMP = 'bitslice_sb32' )

  for TYPE in [ 'PHOTON_RV32_TYPE1', 'PHOTON_RV32_TYPE2' ] :
    for UNROLL in [ False, True ] :
      CONF = [ TYPE ]

      if ( UNROLL ) :
        CONF += [ 'PHOTON_RV32_UNROLL' ]

      driver.run( args, 'photon', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'photon', CONF, 'rv64', 'nist', NIST_IMP = 'ref'           )
    driver.run( args, 'photon', CONF, 'rv64', 'nist', NIST_IMP = 'table2'        )
    driver.run( args, 'photon', CONF, 'rv64', 'nist', NIST_IMP = 'table3'        )
    driver.run( args, 'photon', CONF, 'rv64', 'nist', NIST_IMP = 'bitslice_sb64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
