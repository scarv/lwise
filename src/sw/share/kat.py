# Copyright (C) 2021 SCARV project <info@scarv.org>
#
# Use of this source code is restricted per the MIT license, a copy of which 
# can be found at https://opensource.org/licenses/MIT (or should be included 
# as LICENSE.txt within the associated archive or repository).

import argparse, binascii, sys

# =============================================================================

def array( xs ) :
  return ( ( '0', 'NULL' ) ) if ( xs == None ) else ( ( len( xs ), '"' + ''.join( [ '%02X' % x for x in xs ] ) + '"' ) )

# -----------------------------------------------------------------------------

def generate_header() :
  print( '#ifndef __KAT_H'          )
  print( '#define __KAT_H'          )

  print( '#include <stddef.h>'      )
  print( '#include <stdint.h>'      )

  print( 'typedef struct {'         )
  print( '                long            i;' )
  print( '  unsigned long long k_n; char* k;' )
  print( '  unsigned long long n_n; char* n;' )
  print( '  unsigned long long a_n; char* a;' )
  print( '  unsigned long long m_n; char* m;' )
  print( '  unsigned long long c_n; char* c;' )
  print( '} kat_t;'                 )

  print( 'extern kat_t KAT[];'      )

  print( '#endif'                   )

def generate_source() :
  rs = list() ; f = False
  
  while ( not f ) :
    r  = dict()
  
    while ( True ) :
      l = sys.stdin.readline()
  
      if ( l == '' ) : # EOF
        f = True  ; break
  
      l = l.strip()
  
      if ( l == '' ) : # EOR
        f = False ; break 
  
      l = [ x.strip() for x in l.split( '=' ) ]
  
      if   ( l[ 0 ] == 'Count' ) :
        r[ 'i' ] =              int( l[ 1 ] )
      elif ( l[ 0 ] == 'Key'   ) :
        r[ 'k' ] = binascii.a2b_hex( l[ 1 ] )
      elif ( l[ 0 ] == 'Nonce' ) :
        r[ 'n' ] = binascii.a2b_hex( l[ 1 ] )
      elif ( l[ 0 ] == 'AD'    ) :
        r[ 'a' ] = binascii.a2b_hex( l[ 1 ] )
      elif ( l[ 0 ] == 'PT'    ) :
        r[ 'm' ] = binascii.a2b_hex( l[ 1 ] )
      elif ( l[ 0 ] == 'CT'    ) :
        r[ 'c' ] = binascii.a2b_hex( l[ 1 ] )
  
    if ( set( r.keys() ) == set( [ 'i', 'k', 'n', 'a', 'm', 'c' ] ) ) :
      rs.append( r )

  rs.append( { 'i' : -1, 'k' : None, 'n' : None, 'a' : None, 'm' : None, 'c' : None } )
  
  print( '#include "kat.h"' );

  print( 'kat_t KAT[] = {' );
  
  for ( i, r ) in enumerate( rs ) :
    if ( i != 0 ) :
      print( ',' )
  
    print( '{' )
  
    print(             '.i = {0},'.format(    int( r[ 'i' ] ) ) )
    print( '.k_n = {0}, .k = {1},'.format( *array( r[ 'k' ] ) ) )
    print( '.n_n = {0}, .n = {1},'.format( *array( r[ 'n' ] ) ) )
    print( '.a_n = {0}, .a = {1},'.format( *array( r[ 'a' ] ) ) )
    print( '.m_n = {0}, .m = {1},'.format( *array( r[ 'm' ] ) ) )
    print( '.c_n = {0}, .c = {1} '.format( *array( r[ 'c' ] ) ) )
  
    print( '}' )
  
  print( '};' );

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--header', dest = 'header', action = 'store_true', default = False )
  parser.add_argument( '--source', dest = 'source', action = 'store_true', default = False )

  args = parser.parse_args()

  if ( args.header ) :
    generate_header()  
  if ( args.source ) :
    generate_source()  

# =============================================================================
