#ifndef _INCLUDE_MODKILL_LSL_
#define _INCLUDE_MODKILL_LSL_

list modkill(string base, list l, integer index) {
   if (!llGetListLength(l)) {
      return l;
   }

   integer basenum = llListFindList(l, [ base ]);
   if (basenum == -1) {
      basenum = 0;
   }
   basenum = (basenum + index + llGetListLength(l)) % llGetListLength(l);
   return llDeleteSubList(l, basenum, basenum);
}

#endif
