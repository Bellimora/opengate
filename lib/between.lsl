#ifndef _INCLUDE_BETWEEN_LSL_
#define _INCLUDE_BETWEEN_LSL_

integer between(string a, string b, string c) {
   list l = llListSort([a,b,c], 1, TRUE);

   if (a == b || b == c || a == c) {
      return 0;
   }

   if (a == llList2String(l, 0) && b == llList2String(l, 1)) {
      return 1;
   }
   if (b == llList2String(l, 0) && c == llList2String(l, 1)) {
      return 1;
   }
   if (c == llList2String(l, 0) && a == llList2String(l, 1)) {
      return 1;
   }

   return 0;
}

#endif
