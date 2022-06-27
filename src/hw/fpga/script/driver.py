# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import argparse, os, subprocess

# =============================================================================

def run( args, ALG, CONF, ARCH, IMP, NIST_IMP = None ) :
  CONF  = ' '.join( [ '-D%s' % ( x ) for x in CONF ] )

  CONF += ( ' ' if ( CONF != '' ) else '' ) + '-DDRIVER_TRIALS_WARN="%d"' % ( args.trials_warm )
  CONF += ( ' ' if ( CONF != '' ) else '' ) + '-DDRIVER_TRIALS_REAL="%d"' % ( args.trials_real )

  print( '>>> ALG      = "%s"' % ( ALG      ) )
  print( '>>> CONF     = "%s"' % ( CONF     ) )
  print( '>>> ARCH     = "%s"' % ( ARCH     ) )
  print( '>>>      IMP = "%s"' % (      IMP ) )
  print( '>>> NIST_IMP = "%s"' % ( NIST_IMP ) )

  env = dict()

  env[ 'REPO_HOME'    ] = os.environ[ 'REPO_HOME'    ]
  env[ 'REPO_VERSION' ] = os.environ[ 'REPO_VERSION' ]

  env[ 'PORT'            ] = os.environ[ 'PORT'    ]
  env[ 'RISCV_ROCKET'    ] = os.environ[ 'RISCV_ROCKET'    ]
  env[ 'ROCKETCHIP_REPO' ] = os.environ[ 'ROCKETCHIP_REPO' ]

  if ( NIST_IMP != None ) :
    env.update( { 'ALG' : ALG, 'FPGA_SWCONF' : CONF, 'ARCH' : ARCH, 'IMP' : IMP, 'NIST_IMP' : NIST_IMP } )
  else :
    env.update( { 'ALG' : ALG, 'FPGA_SWCONF' : CONF, 'ARCH' : ARCH, 'IMP' : IMP                        } )

  subprocess.run( [ 'make', os.path.expandvars( '--directory=${REPO_HOME}/src/hw' ), 'fpga-swclean', 'fpga-run' ], env = env )

  print( '<<<'                                )

def program_fpga( args, ALG, ARCH, ISE = 'xalu' ) :
  print( '>>> ALG = "%s", ARCH = "%s", ISE = "%s"' % ( ALG, ARCH, ISE ) )
  print( '>>> Program FPGA ...')

  env = dict()
  env[ 'PATH'            ] = os.environ[ 'PATH'            ]
  env[ 'HOME'            ] = os.environ[ 'HOME'            ]
  env[ 'REPO_HOME'       ] = os.environ[ 'REPO_HOME'       ]
  env[ 'REPO_VERSION'    ] = os.environ[ 'REPO_VERSION'    ]
  env[ 'RISCV_ROCKET'    ] = os.environ[ 'RISCV_ROCKET'    ]
  env[ 'ROCKETCHIP_REPO' ] = os.environ[ 'ROCKETCHIP_REPO' ]

  env.update( { 'ALG' : ALG, 'ARCH' : ARCH, 'ISE' : ISE } )
  subprocess.run( [ 'make', '--quiet', os.path.expandvars( '--directory=${REPO_HOME}/src/hw' ), 'program-fpga' ], env = env, stdout=subprocess.DEVNULL)
  print( '>>> Done.')
# -----------------------------------------------------------------------------

def main( rv32, rv64 ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--rv32',        dest = 'rv32',        action = 'store_true',        default = False )
  parser.add_argument( '--rv64',        dest = 'rv64',        action = 'store_true',        default = False )

  parser.add_argument( '--nist',        dest = 'nist',        action = 'store_true',        default = False )

  parser.add_argument( '--prog',        dest = 'prog',        action = 'store_true',        default = False )

  parser.add_argument( '--trials-warm', dest = 'trials_warm', action = 'store', type = int, default = 10  )
  parser.add_argument( '--trials-real', dest = 'trials_real', action = 'store', type = int, default = 50  )

  args = parser.parse_args()

  if ( args.rv32 ) :
    rv32( args )
  if ( args.rv64 ) :
    rv64( args )

# =============================================================================
