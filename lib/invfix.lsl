#ifndef _INCLUDE_INVFIX_LSL_
#define _INCLUDE_INVFIX_LSL_

list llGetInventoryList(integer type) {
   list result;
   integer size;
   string tmp1;
   string tmp2;
   integer i;
   integer done = 0;

   while (!done) {
      done = 1;
      result = [];
      size = llGetInventoryNumber(type);
      for (i = 0; i < size; i++) {
         result = result + [ llGetInventoryName(type, i) ];
      }
      for (i = 0; done && i < llGetInventoryNumber(type); i++) {
         if (llGetInventoryNumber(type) != size) {
            done = 0;
         }
         else {
            tmp1 = llGetInventoryName(type, i);
            tmp2 = llList2String(result, i);
            if (tmp1 != tmp2 || tmp1 == "" || tmp2 == "") {
               done = 0;
            }
         }
      }
   }
   return result;
}

#define llGetInventoryName(x,y) UNSAFE_llGetInventoryName_ERROR

#endif
