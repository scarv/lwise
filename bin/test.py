# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import os, subprocess, sys

if ( __name__ == '__main__' ) :
  def run( ARCH, IMP, CONF ) :
    CONF = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

    print( '>>> ARCH = "%s"' % ( ARCH ) )
    print( '>>> IMP  = "%s"' % ( IMP  ) )
    print( '>>> CONF = "%s"' % ( CONF ) )

    subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/software' ), 'clean', 'all', 'run' ], env = { **os.environ, 'ARCH' : ARCH, 'IMP' : IMP, 'CONF' : CONF } )

    print( '<<<'                        )

  trials = 1000

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
        CONF  = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]
        CONF += [ TYPE, 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', 'TRAXL17_ENC_EXTERN', 'TRAXL17_DEC_EXTERN' ]

        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]
        if ( BITMANIP ) :
          CONF += [ 'RV32B' ]

        run( 'rv32',    'rv32', CONF )

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
        CONF  = [ 'DRIVER_TRIALS=%d' % ( trials ), 'DRIVER_MEASURE' ]
        CONF += [ TYPE, 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', 'TRAXL17_ENC_EXTERN', 'TRAXL17_DEC_EXTERN' ]

        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL', 'TRAXL17_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL', 'TRAXL17_DEC_UNROLL' ]
        if ( BITMANIP ) :
          CONF += [ 'RV64B' ]

        run( 'rv64',    'rv64', CONF )
