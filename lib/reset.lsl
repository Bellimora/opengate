#ifndef _INCLUDE_RESET_LSL
#define _INCLUDE_RESET_LSL

#include "invfix.lsl"

void reset() {
   list l = llGetInventoryList(INVENTORY_SCRIPT);
   integer i;
   for (i = 0; i < llGetListLength(l); i++) {
      if (!llGetScriptState(llList2String(l, i))) {
         llResetOtherScript(llList2String(l, i));
      }
   }
}

#endif
