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
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        share.run( 'sparkle', 'rv32', 'generic', CONF )

  # rv32/rv32

  for UNROLL in [ False, True ] :
    for TYPE in [ 'SPARKLE_RV32_TYPE1', 'SPARKLE_RV32_TYPE2', 'SPARKLE_RV32_TYPE3', 'SPARKLE_RV32_TYPE4'                       ] :
      for ( ELL, RCON ) in itertools.product( [ False, True ], repeat = 2 ) :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
        CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
        CONF += [ 'DRIVER_TRIALS_KAT'  ]
        CONF += [ 'DRIVER_TRIALS_BIST' ]
        CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
      
        CONF += [ TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        if ( ELL      ) :
          CONF += [ 'SPARKLE_RV32_ELL'  ]
        if ( RCON     ) :
          CONF += [ 'SPARKLE_RV32_RCON' ]
    
        share.run( 'sparkle', 'rv32',    'rv32', CONF )

# -----------------------------------------------------------------------------

def rv64( args ) :
  # rv64/generic

  for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
        CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
        CONF += [ 'DRIVER_TRIALS_KAT'  ]
        CONF += [ 'DRIVER_TRIALS_BIST' ]
        CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        share.run( 'sparkle', 'rv64', 'generic', CONF )

  # rv64/rv64

  for UNROLL in [ False, True ] :
    for TYPE in [ 'SPARKLE_RV64_TYPE1', 'SPARKLE_RV64_TYPE2', 'SPARKLE_RV64_TYPE3', 'SPARKLE_RV64_TYPE4', 'SPARKLE_RV64_TYPE5' ] :
      for ( ELL, RCON ) in itertools.product( [ False, True ], repeat = 2 ) :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ) ]
        CONF += [ 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ) ]
        CONF += [ 'DRIVER_TRIALS_KAT'  ]
        CONF += [ 'DRIVER_TRIALS_BIST' ]
        CONF += [ 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ) ]
      
        CONF += [ TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        if ( ELL      ) :
          CONF += [ 'SPARKLE_RV64_ELL'  ]
        if ( RCON     ) :
          CONF += [ 'SPARKLE_RV64_RCON' ]

        share.run( 'sparkle', 'rv64',    'rv64', CONF )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  share.driver( rv32, rv64 )

# =============================================================================
