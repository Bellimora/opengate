#ifndef _INCLUDE_FLAGS_LSL
#define _INCLUDE_FLAGS_LSL

#include "objname.lsl"
#include "objdesc.lsl"
#include "aunescape.lsl"

list flags() {
   list ret = [];
   list tmp = llParseString2List(llGetObjectName(), [], [ "{", "}" ]) + llParseString2List(llGetObjectDesc(), [], [ "{", "}" ]);
   integer i;

   for (i = 0; i < llGetListLength(tmp); i++) {
      if (llList2String(tmp, i) == "{" && llGetListLength(tmp) > i+1) {
         string flag = llToLower(aunescape(llList2String(tmp, i+1)));
         if (-1 == llListFindList(ret, [ flag ])) {
            ret = ret + flag;
         }
      }
   }

   return ret;
}

#endif
