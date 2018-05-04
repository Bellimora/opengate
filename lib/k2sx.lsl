#ifndef _INCLUDE_K2SX_LSL_
#define _INCLUDE_K2SX_LSL_

string k2sx(key k, string symbols) {
   string ret = "";
   integer a = (integer) ("0x"+llGetSubString((string)k,0,5));
   integer rem;
   integer i;

   for (i = 0; i < 7; i++) {
      rem = a % 11;
      a = a / 11;
      ret = ret + llGetSubString(symbols, rem, rem);
      symbols = llDeleteSubString(symbols, rem, rem);
   }

   return ret;
}

#endif
