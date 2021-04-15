# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import os, subprocess, sys

if ( __name__ == '__main__' ) :
  def run( ARCH, CONF ) :
    print( [ 'make', os.path.expandvars( '--directory="${REPO_HOME}/src/alzette"' ), 'ARCH="%s"' % ( ARCH ), 'CONF="%s"' % ( ' '.join( [ '-D%s' % ( x ) for x in CONF ] ) ), 'clean', 'all', 'run' ] )

  for TYPE in [ 'RV32_TYPE1', 'RV32_TYPE2', 'RV32_TYPE3', 'RV32_TYPE4'               ] :
    for BITMANIP in [ False, True ] :
      for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=10', 'DRIVER_MEASURE', TYPE ]

        if ( BITMANIP ) :
          CONF += [ '-DRV32B' ]
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL' ]

        run( 'rv32', CONF )

  for TYPE in [ 'RV64_TYPE1', 'RV64_TYPE2', 'RV64_TYPE3', 'RV64_TYPE4', 'RV64_TYPE5' ] :
    for BITMANIP in [ False, True ] :
      for UNROLL in [ False, True ] :
        CONF  = [ 'DRIVER_TRIALS=10', 'DRIVER_MEASURE', TYPE ]

        if ( BITMANIP ) :
          CONF += [ '-DRV64B' ]
        if ( UNROLL   ) :
          CONF += [ 'CRAXS10_ENC_UNROLL' ]
          CONF += [ 'CRAXS10_DEC_UNROLL' ]

        run( 'rv64', CONF )
