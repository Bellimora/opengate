#ifndef _INCLUDE_BYTE2HEX_LSL_
#define _INCLUDE_BYTE2HEX_LSL_

string byte2hex(integer x) {
   string hexc="0123456789ABCDEF";
   return llGetSubString(hexc, x = ((x >> 4) & 0xF), x) + llGetSubString(hexc, (x & 0xF), (x & 0xF));
}

#endif
