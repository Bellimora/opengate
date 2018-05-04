#ifndef _INCLUDE_PRUNE_LSL_
#define _INCLUDE_PRUNE_LSL_

#include "uniq.lsl"

// sort list, removing blank entries and duplicates

list prune(list l) {
   return llListSort(uniq(l), 1, TRUE);
}

#endif
