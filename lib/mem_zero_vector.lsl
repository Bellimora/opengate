#ifndef _INCLUDE_MEM_ZERO_VECTOR_LSL_
#define _INCLUDE_MEM_ZERO_VECTOR_LSL_

// this saves approx 10 bytes per reference to ZERO_VECTOR
// but costs an extra 31 bytes for the script

vector zero_vector = ZERO_VECTOR;
#define ZERO_VECTOR zero_vector

#endif
