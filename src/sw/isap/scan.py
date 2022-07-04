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

    driver.run( args, 'isap', CONF, 'rv32', 'nist', NIST_IMP = 'ref'    )
    driver.run( args, 'isap', CONF, 'rv32', 'nist', NIST_IMP = 'opt_32' )

  for TYPE in [ 'ISAP_RV32_TYPE1', 'ISAP_RV32_TYPE2'] :
    CONF = [ TYPE ]

    driver.run( args, 'isap', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'isap', CONF, 'rv64', 'nist', NIST_IMP = 'ref'    )
    driver.run( args, 'isap', CONF, 'rv64', 'nist', NIST_IMP = 'opt_64' )

  for TYPE in [ 'ISAP_RV64_TYPE1' ] :
    CONF = [ TYPE ]

    driver.run( args, 'isap', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
