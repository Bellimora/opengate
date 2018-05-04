#ifndef _INCLUDE_INT2HEX_LSL_
#define _INCLUDE_INT2HEX_LSL_

string hexc="0123456789ABCDEF";

string int2hex(integer x) 
{
   string res = "";
   integer i;
   integer x0;

   for (i = 0; i < 8; i++) {
      x0 = x & 0xF;
      res = llGetSubString(hexc, x0, x0) + res;
      x = x >> 4;
   }

   res = "0x" + res;

   return res;
}

#endif
