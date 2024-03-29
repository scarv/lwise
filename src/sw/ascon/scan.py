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

    driver.run( args, 'ascon', CONF, 'rv32', 'nist', NIST_IMP = 'ref'           )
    driver.run( args, 'ascon', CONF, 'rv32', 'nist', NIST_IMP = 'bi32'          )
    driver.run( args, 'ascon', CONF, 'rv32', 'nist', NIST_IMP = 'bi32_lowreg'   )
    driver.run( args, 'ascon', CONF, 'rv32', 'nist', NIST_IMP = 'bi32_lowsize'  )

  for TYPE in [ 'ASCON_RV32_TYPE1', 'ASCON_RV32_TYPE2' ] :
    CONF = [ TYPE ]
    # there is only unrolled implementation for Ascon on rv32
    CONF += ['ASCON_RV32_UNROLL']

    driver.run( args, 'ascon', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  if ( args.nist ) :
    CONF = []

    driver.run( args, 'ascon', CONF, 'rv64', 'nist', NIST_IMP = 'ref'           )
    driver.run( args, 'ascon', CONF, 'rv64', 'nist', NIST_IMP = 'opt64'         )
    driver.run( args, 'ascon', CONF, 'rv64', 'nist', NIST_IMP = 'opt64_lowsize' )

  for TYPE in [ 'ASCON_RV64_TYPE1', 'ASCON_RV64_TYPE2' ] :
    CONF = [ TYPE ]
    # there is only unrolled implementation for Ascon on rv64
    CONF += ['ASCON_RV64_UNROLL']

    driver.run( args, 'ascon', CONF, 'rv64', 'rv64' )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
