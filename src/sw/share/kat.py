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
  if   ( args.api == 'aead' ) :
    print( '#ifndef __KAT_AEAD_H'               )
    print( '#define __KAT_AEAD_H'               )

    print( '#include <stddef.h>'                )
    print( '#include <stdint.h>'                )

    print( 'typedef struct {'                   )
    print( '                long            i;' )
    print( '  unsigned long long k_n; char* k;' )
    print( '  unsigned long long n_n; char* n;' )
    print( '  unsigned long long a_n; char* a;' )
    print( '  unsigned long long m_n; char* m;' )
    print( '  unsigned long long c_n; char* c;' )
    print( '} kat_aead_t;'                      )

    print( 'extern kat_aead_t KAT_AEAD[];'      )

    print( '#endif'                             )

  elif ( args.api == 'hash' ) :
    print( '#ifndef __KAT_HASH_H'               )
    print( '#define __KAT_HASH_H'               )

    print( '#include <stddef.h>'                )
    print( '#include <stdint.h>'                )

    print( 'typedef struct {'                   )
    print( '                long            i;' )
    print( '  unsigned long long m_n; char* m;' )
    print( '  unsigned long long d_n; char* d;' )
    print( '} kat_hash_t;'                      )

    print( 'extern kat_hash_t KAT_HASH[];'      )

    print( '#endif'                             )

# -----------------------------------------------------------------------------

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

      if   ( args.api == 'aead' ) :
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

      elif ( args.api == 'hash' ) :
        if   ( l[ 0 ] == 'Count' ) :
          r[ 'i' ] =              int( l[ 1 ] )
        elif ( l[ 0 ] == 'Msg'   ) :
          r[ 'm' ] = binascii.a2b_hex( l[ 1 ] )
        elif ( l[ 0 ] == 'MD'    ) :
          r[ 'd' ] = binascii.a2b_hex( l[ 1 ] )
  
    if   ( ( args.api == 'aead' ) and ( set( r.keys() ) == set( [ 'i', 'k', 'n', 'a', 'm', 'c' ] ) ) ) :
      rs.append( r )
    elif ( ( args.api == 'hash' ) and ( set( r.keys() ) == set( [ 'i', 'm', 'd'                ] ) ) ) :
      rs.append( r )

  if   ( args.api == 'aead' ) :
    rs.append( { 'i' : -1, 'k' : None, 'n' : None, 'a' : None, 'm' : None, 'c' : None } )
  elif ( args.api == 'hash' ) :
    rs.append( { 'i' : -1, 'm' : None, 'd' : None                                     } )

  if   ( args.api == 'aead' ) :
    print( '#include "kat_aead.h"' )

    print( 'kat_aead_t KAT_AEAD[] = {' );

  elif ( args.api == 'hash' ) :
    print( '#include "kat_hash.h"' )

    print( 'kat_hash_t KAT_HASH[] = {' );
  
  for ( i, r ) in enumerate( rs ) :
    if ( i != 0 ) :
      print( ',' )
  
    print( '{' )
  
    if   ( args.api == 'aead' ) :
      print(             '.i = {0},'.format(    int( r[ 'i' ] ) ) )
      print( '.k_n = {0}, .k = {1},'.format( *array( r[ 'k' ] ) ) )
      print( '.n_n = {0}, .n = {1},'.format( *array( r[ 'n' ] ) ) )
      print( '.a_n = {0}, .a = {1},'.format( *array( r[ 'a' ] ) ) )
      print( '.m_n = {0}, .m = {1},'.format( *array( r[ 'm' ] ) ) )
      print( '.c_n = {0}, .c = {1} '.format( *array( r[ 'c' ] ) ) )

    elif ( args.api == 'hash' ) :
      print(             '.i = {0},'.format(    int( r[ 'i' ] ) ) )
      print( '.m_n = {0}, .m = {1},'.format( *array( r[ 'm' ] ) ) )
      print( '.d_n = {0}, .d = {1},'.format( *array( r[ 'd' ] ) ) )
  
    print( '}' )
  
  print( '};' );

# -----------------------------------------------------------------------------

if ( __name__ == '__main__' ) :
  parser = argparse.ArgumentParser()

  parser.add_argument( '--api',    dest =    'api', choices = [ 'aead', 'hash' ], default = 'aead' )

  parser.add_argument( '--header', dest = 'header', action = 'store_true',        default = False  )
  parser.add_argument( '--source', dest = 'source', action = 'store_true',        default = False  )

  args = parser.parse_args()

  if ( args.header ) :
    generate_header()  
  if ( args.source ) :
    generate_source()  

# =============================================================================
