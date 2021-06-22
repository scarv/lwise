# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import argparse, os, subprocess

# =============================================================================

MEASURE = [ 'average', 'minimum', 'maximum' ]

# -----------------------------------------------------------------------------

def run( ALG, ARCH, IMP, CONF ) :
  CONF = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

  print( '>>> ALG  = "%s"' % ( ALG  ) )
  print( '>>> ARCH = "%s"' % ( ARCH ) )
  print( '>>> IMP  = "%s"' % ( IMP  ) )
  print( '>>> CONF = "%s"' % ( CONF ) )

  subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/software' ), 'clean', 'build', 'run' ], env = { **os.environ, 'ALG' : ALG, 'ARCH' : ARCH, 'IMP' : IMP, 'CONF' : CONF } )

  print( '<<<'                        )

# -----------------------------------------------------------------------------

def driver( rv32, rv64 ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--rv32',        dest = 'rv32',        action = 'store_true',                           default = False     )
  parser.add_argument( '--rv64',        dest = 'rv64',        action = 'store_true',                           default = False     )

  parser.add_argument( '--trials-warm', dest = 'trials_warm', action = 'store', type = int,                    default =   10      )
  parser.add_argument( '--trials-real', dest = 'trials_real', action = 'store', type = int,                    default = 1000      )

  parser.add_argument( '--measure',     dest = 'measure',     action = 'store', type = str, choices = MEASURE, default = 'average' )

  args = parser.parse_args()

  if ( args.rv32 ) :
    rv32( args )
  if ( args.rv64 ) :
    rv64( args )

# =============================================================================
