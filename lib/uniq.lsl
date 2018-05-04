#ifndef _INCLUDE_UNIQ_LSL_
#define _INCLUDE_UNIQ_LSL_

// remove blank and duplicate entries from a list

list uniq(list l) {
   list ret;
   integer i;
   string tmp;
   for (i = llGetListLength(l) - 1; i >= 0; i--) {
      tmp = llList2String(l, i);
      if (tmp != "" && -1 == llListFindList(ret, [ tmp ])) {
         ret = [ tmp ] + ret;
      }
   }
   return ret;
}

#endif
