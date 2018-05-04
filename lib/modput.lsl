#ifndef _INCLUDE_MODPUT_LSL_
#define _INCLUDE_MODPUT_LSL_

list modput(string base, list l, integer index, string value) {
   if (!llGetListLength(l)) {
      return [ value ];
   }

   integer basenum = llListFindList(l, [ base ]);
   if (basenum == -1) {
      basenum = 0;
   }
   basenum = (basenum + index + llGetListLength(l)) % llGetListLength(l);
   return llListReplaceList(l, [ value ], basenum, basenum);
}

#endif
