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
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ), 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ), 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) )       ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        share.run( 'alzette', 'rv32', 'generic', CONF )

  # rv32/rv32

  for UNROLL in [ False, True ] :
    for TYPE in [ 'ALZETTE_RV32_TYPE1', 'ALZETTE_RV32_TYPE2', 'ALZETTE_RV32_TYPE3', 'ALZETTE_RV32_TYPE4'                       ] :
      for ( BITMANIP, ELL, RCON ) in itertools.product( [ False, True ], repeat = 3 ) :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ), 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ), 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ), TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        CONF += [ 'CRAXS10_ENC_EXTERN', 'TRAXL17_ENC_EXTERN', 'SPARKLE_FWD_EXTERN' ]
        CONF += [ 'CRAXS10_DEC_EXTERN', 'TRAXL17_DEC_EXTERN', 'SPARKLE_REV_EXTERN' ]

        if ( BITMANIP ) :
          CONF += [ 'ALZETTE_RV32B'     ]
        if ( ELL      ) :
          CONF += [ 'ALZETTE_RV32_ELL'  ]
        if ( RCON     ) :
          CONF += [ 'ALZETTE_RV32_RCON' ]
    
        share.run( 'alzette', 'rv32',    'rv32', CONF )

# -----------------------------------------------------------------------------

def rv64( args ) :
  # rv64/generic

  for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ), 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ), 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) )       ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        share.run( 'alzette', 'rv64', 'generic', CONF )

  # rv64/rv64

  for UNROLL in [ False, True ] :
    for TYPE in [ 'ALZETTE_RV64_TYPE1', 'ALZETTE_RV64_TYPE2', 'ALZETTE_RV64_TYPE3', 'ALZETTE_RV64_TYPE4', 'ALZETTE_RV64_TYPE5' ] :
      for ( BITMANIP, ELL, RCON ) in itertools.product( [ False, True ], repeat = 3 ) :
        CONF  = [ 'DRIVER_TRIALS_WARM=%d' % ( args.trials_warm ), 'DRIVER_TRIALS_REAL=%d' % ( args.trials_real ), 'DRIVER_MEASURE=%d' % ( share.MEASURE.index( args.measure ) ), TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        CONF += [ 'CRAXS10_ENC_EXTERN', 'TRAXL17_ENC_EXTERN', 'SPARKLE_FWD_EXTERN' ]
        CONF += [ 'CRAXS10_DEC_EXTERN', 'TRAXL17_DEC_EXTERN', 'SPARKLE_REV_EXTERN' ]

        if ( BITMANIP ) :
          CONF += [ 'ALZETTE_RV64B'    ]
        if ( ELL      ) :
          CONF += [ 'ALZETTE_RV64_ELL' ]
        if ( RCON     ) :
          CONF += [ 'ALZETTE_RV64_RCON' ]

        share.run( 'alzette', 'rv64',    'rv64', CONF )

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  share.driver( rv32, rv64 )

# =============================================================================
