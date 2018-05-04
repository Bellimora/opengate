#ifndef _INCLUDE_MODGET_LSL_
#define _INCLUDE_MODGET_LSL_

string modget(string base, list l, integer index) {
   if (!llGetListLength(l)) {
      return "";
   }

   integer basenum = llListFindList(l, [ base ]);

   if (basenum == -1) {
      basenum = 0;
   }

   return llList2String(l,
         (basenum + index + llGetListLength(l)) % llGetListLength(l));
}

#endif
