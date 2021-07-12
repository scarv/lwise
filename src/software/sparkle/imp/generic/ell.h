/* Copyright (C) 2021 SCARV project <info@scarv.org>
 *
 * Use of this source code is restricted per the MIT license, a copy of which 
 * can be found at https://opensource.org/licenses/MIT (or should be included 
 * as LICENSE.txt within the associated archive or repository).
 */

#ifndef __ELL_H
#define __ELL_H

#define ELL(x) ( ROR32( ( (x) ^ ( (x) << 16 ) ), 16 ) )

#endif
