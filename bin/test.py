# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import argparse, os, subprocess, sys

def run( ARCH, IMP, CONF ) :
  CONF = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

  print( '>>> ARCH = "%s"' % ( ARCH ) )
  print( '>>> IMP  = "%s"' % ( IMP  ) )
  print( '>>> CONF = "%s"' % ( CONF ) )

  subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/software' ), 'clean', 'all', 'run' ], env = { **os.environ, 'ARCH' : ARCH, 'IMP' : IMP, 'CONF' : CONF } )

  print( '<<<'                        )

def rv32( trials ) :
  # rv32/generic

  for UNROLL in [ False, True ] :
          CONF  = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]

          if ( UNROLL   ) :
            CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
            CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]

          run( 'rv32', 'generic', CONF )

  # rv32/rv32

  for UNROLL in [ False, True ] :
    for TYPE in [ 'RV32_TYPE1', 'RV32_TYPE2', 'RV32_TYPE3', 'RV32_TYPE4'               ] :
      for BITMANIP in [ False, True ] :
        for ELL in [ False, True ] :
          CONF  = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]
          CONF += [ TYPE, 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', 'TRAXL17_ENC_EXTERN', 'TRAXL17_DEC_EXTERN' ]

          if ( UNROLL   ) :
            CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
            CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]
          if ( BITMANIP ) :
            CONF += [ 'RV32B'    ]
          if ( ELL      ) :
            CONF += [ 'RV32_ELL' ]


        run( 'rv32',    'rv32', CONF )

def rv64( trials ) :
  # rv64/generic

  for UNROLL in [ False, True ] :
          CONF = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]

          if ( UNROLL   ) :
            CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
            CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]

          run( 'rv64', 'generic', CONF )

  # rv64/rv64

  for UNROLL in [ False, True ] :
    for TYPE in [ 'RV64_TYPE1', 'RV64_TYPE2', 'RV64_TYPE3', 'RV64_TYPE4', 'RV64_TYPE5' ] :
      for BITMANIP in [ False, True ] :
        for ELL in [ False, True ] :
          CONF  = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]
          CONF += [ TYPE, 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', 'TRAXL17_ENC_EXTERN', 'TRAXL17_DEC_EXTERN' ]

          if ( UNROLL   ) :
            CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
            CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]
          if ( BITMANIP ) :
            CONF += [ 'RV64B'    ]
          if ( ELL      ) :
            CONF += [ 'RV64_ELL' ]


        run( 'rv64',    'rv64', CONF )

if ( __name__ == '__main__' ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--trials', dest = 'trials', action = 'store', type = int, default = 1000  )

  parser.add_argument( '--rv32',   dest =   'rv32', action = 'store_true',        default = False )
  parser.add_argument( '--rv64',   dest =   'rv64', action = 'store_true',        default = False )

  args = parser.parse_args()

  if ( args.rv32 ) :
    rv32( args.trials )
  if ( args.rv64 ) :
    rv64( args.trials )
