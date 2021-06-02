# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import argparse, itertools, os, subprocess, sys

MEASURE = [ 'average', 'minimum', 'maximum' ]

def test( ARCH, IMP, CONF ) :
  CONF = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

  print( '>>> ARCH = "%s"' % ( ARCH ) )
  print( '>>> IMP  = "%s"' % ( IMP  ) )
  print( '>>> CONF = "%s"' % ( CONF ) )

  subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/software' ), 'clean', 'all', 'run' ], env = { **os.environ, 'ARCH' : ARCH, 'IMP' : IMP, 'CONF' : CONF } )

  print( '<<<'                        )

def test_rv32( args ) :
  # rv32/generic

  for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=%d' % ( args.trials ), 'DRIVER_MEASURE=%d' % ( MEASURE.index( args.measure ) ) ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        test( 'rv32', 'generic', CONF )

  # rv32/rv32

  for UNROLL in [ False, True ] :
    for TYPE in [ 'RV32_TYPE1', 'RV32_TYPE2', 'RV32_TYPE3', 'RV32_TYPE4'               ] :
      for ( BITMANIP, ELL, RCON ) in itertools.product( [ False, True ], repeat = 3 ) :
        CONF  = [ 'DRIVER_TRIALS=%d' % ( args.trials ), 'DRIVER_MEASURE=%d' % ( MEASURE.index( args.measure ) ), TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        CONF += [ 'CRAXS10_ENC_EXTERN', 'TRAXL17_ENC_EXTERN', 'SPARKLE_FWD_EXTERN' ]
        CONF += [ 'CRAXS10_DEC_EXTERN', 'TRAXL17_DEC_EXTERN', 'SPARKLE_REV_EXTERN' ]

        if ( BITMANIP ) :
          CONF += [ 'RV32B'     ]
        if ( ELL      ) :
          CONF += [ 'RV32_ELL'  ]
        if ( RCON     ) :
          CONF += [ 'RV32_RCON' ]
    
        test( 'rv32',    'rv32', CONF )

def test_rv64( args ) :
  # rv64/generic

  for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=%d' % ( args.trials ), 'DRIVER_MEASURE=%d' % ( MEASURE.index( args.measure ) ) ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]
  
        test( 'rv64', 'generic', CONF )

  # rv64/rv64

  for UNROLL in [ False, True ] :
    for TYPE in [ 'RV64_TYPE1', 'RV64_TYPE2', 'RV64_TYPE3', 'RV64_TYPE4', 'RV64_TYPE5' ] :
      for ( BITMANIP, ELL, RCON ) in itertools.product( [ False, True ], repeat = 3 ) :
        CONF  = [ 'DRIVER_TRIALS=%d' % ( args.trials ), 'DRIVER_MEASURE=%d' % ( MEASURE.index( args.measure ) ), TYPE ]
  
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL', 'SPARKLE_FWD_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL', 'SPARKLE_REV_UNROLL' ]

        CONF += [ 'CRAXS10_ENC_EXTERN', 'TRAXL17_ENC_EXTERN', 'SPARKLE_FWD_EXTERN' ]
        CONF += [ 'CRAXS10_DEC_EXTERN', 'TRAXL17_DEC_EXTERN', 'SPARKLE_REV_EXTERN' ]

        if ( BITMANIP ) :
          CONF += [ 'RV64B'    ]
        if ( ELL      ) :
          CONF += [ 'RV64_ELL' ]
        if ( RCON     ) :
          CONF += [ 'RV64_RCON' ]

        test( 'rv64',    'rv64', CONF )

if ( __name__ == '__main__' ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--rv32',    dest =    'rv32', action = 'store_true',                           default = False     )
  parser.add_argument( '--rv64',    dest =    'rv64', action = 'store_true',                           default = False     )

  parser.add_argument( '--trials',  dest =  'trials', action = 'store', type = int,                    default = 1000      )
  parser.add_argument( '--measure', dest = 'measure', action = 'store', type = str, choices = MEASURE, default = 'average' )

  args = parser.parse_args()

  if ( args.rv32 ) :
    test_rv32( args )
  if ( args.rv64 ) :
    test_rv64( args )
