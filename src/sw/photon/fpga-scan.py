# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import driver, itertools

# =============================================================================

def rv32( args ) :
  if ( args.prog ) :
    driver.program_fpga( args, 'photon', 'rv32', 'xalu' )

  if ( args.nist ) :
    CONF = ['DRIVER_TEST_BYPASS']
    driver.run( args, 'photon', CONF, 'rv32', 'nist', NIST_IMP = 'ref'           )


  for TYPE in [ 'PHOTON_RV32_TYPE1', 'PHOTON_RV32_TYPE2' ] :
    CONF = [ TYPE ]
    CONF += [ 'PHOTON_RV32_UNROLL' ]
    CONF += [ 'DRIVER_TEST_BYPASS' ]

    driver.run( args, 'photon', CONF, 'rv32', 'rv32' )

# -----------------------------------------------------------------------------

def rv64( args ) :
  pass

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  driver.main( rv32, rv64 )

# =============================================================================
