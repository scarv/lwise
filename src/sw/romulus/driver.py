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
    
      share.run( 'romulus', 'rv32', 'generic', CONF )

  # rv32/rv32

  for UNROLL in [ False, True ] :
    for TYPE in [ 'ROMULUS_RV32_TYPE1', 'ROMULUS_RV32_TYPE2' ] :
      CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
      CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
      CONF += [ 'DRIVER_TRIALS_KAT'  ]
      CONF += [ 'DRIVER_TRIALS_BIST' ]
      CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
      
      CONF += [ TYPE ]
    
      share.run( 'romulus', 'rv32',    'rv32', CONF )

# -----------------------------------------------------------------------------

def rv64( args ) :
  # rv64/generic

  for UNROLL in [ False, True ] :
      CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
      CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
      CONF += [ 'DRIVER_TRIALS_KAT'  ]
      CONF += [ 'DRIVER_TRIALS_BIST' ]
      CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
  
      share.run( 'romulus', 'rv64', 'generic', CONF )

  # rv64/rv64

  for UNROLL in [ False, True ] :
    for TYPE in [ 'ROMULUS_RV64_TYPE1', 'ROMULUS_RV64_TYPE2' ] :
      CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
      CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
      CONF += [ 'DRIVER_TRIALS_KAT'  ]
      CONF += [ 'DRIVER_TRIALS_BIST' ]
      CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
      
      CONF += [ TYPE ]
  
      share.run( 'romulus', 'rv64',    'rv64', CONF )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  share.driver( rv32, rv64 )

# =============================================================================
