# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import itertools, share

# =============================================================================

def rv32( args ) :
  # rv32/generic 
  for UNROLL in [ False, True ] :
    CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
    CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
    CONF += [ 'DRIVER_TRIALS_KAT'  ]
    CONF += [ 'DRIVER_TRIALS_BIST' ]
    CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]

    if ( UNROLL ) :
      CONF += [ 'XOODOO_PERM_UNROLL' ]

    share.run( 'xoodyak', 'rv32', 'generic', CONF )

# -----------------------------------------------------------------------------

def rv64( args ) :
  pass

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  share.driver( rv32, rv64 )

# =============================================================================
