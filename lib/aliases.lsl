#ifndef _INCLUDE_ALIASES_LSL
#define _INCLUDE_ALIASES_LSL

#include "objname.lsl"
#include "objdesc.lsl"
#include "aunescape.lsl"

list aliases(integer escape, string open, string close) {
   list ret = [];
   list tmp = llParseString2List(llGetObjectName(), [], [ open, close ]) + llParseString2List(llGetObjectDesc(), [], [ open, close ]);
   integer i;

   for (i = 0; i < llGetListLength(tmp); i++) {
      if (llList2String(tmp, i) == open && llGetListLength(tmp) > i+1) {
         string alias = llList2String(tmp, i+1);

         if (!escape) {
            alias = aunescape(alias);
         }

         ret = ret + llToLower(alias);
      }
   }

   return ret;
}

#endif
