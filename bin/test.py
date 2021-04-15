# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import os, subprocess, sys

if ( __name__ == '__main__' ) :
  def run( ARCH, CONF ) :
    CONF = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

    print( '>>> ARCH="%s"' % ( ARCH ) )
    print( '>>> CONF="%s"' % ( CONF ) )

    subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/alzette' ), 'clean', 'all', 'run' ], env = { **os.environ, 'ARCH' : ARCH, 'CONF' : CONF } )

    print( '<<<'                      )

  for TYPE in [ 'RV32_TYPE1', 'RV32_TYPE2', 'RV32_TYPE3', 'RV32_TYPE4'               ] :
    for BITMANIP in [ False, True ] :
      for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=10', 'DRIVER_MEASURE', 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', TYPE ]

        if ( BITMANIP ) :
          CONF += [ 'RV32B' ]
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL' ]

        run( os.path.expandvars( '${REPO_DEV}/src/alzette/rv32' ), CONF )

  for TYPE in [ 'RV64_TYPE1', 'RV64_TYPE2', 'RV64_TYPE3', 'RV64_TYPE4', 'RV64_TYPE5' ] :
    for BITMANIP in [ False, True ] :
      for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=10', 'DRIVER_MEASURE', 'CRAXS10_ENC_EXTERN', 'CRAXS10_DEC_EXTERN', TYPE ]

        if ( BITMANIP ) :
          CONF += [ 'RV64B' ]
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL' ]

        run( os.path.expandvars( '${REPO_DEV}/src/alzette/rv64' ), CONF )
