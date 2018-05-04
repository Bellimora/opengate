#ifndef _INCLUDE_UNICODE2UTF8_LSL_
#define _INCLUDE_UNICODE2UTF8_LSL_

#include "byte2hex.lsl"

// adapted from http://lslwiki.net/lslwiki/wakka.php?wakka=unicode

string unicode2utf8(integer a) {
   if(a <= 0) return "";//unicode & utf8 only support 2^31 characters, not 2^32; so no negitives.
   integer b = (a >= 0x80) + (a >= 0x800) + (a >= 0x10000) + (a >= 0x200000) + (a >= 0x4000000);
   string c = "%" + byte2hex((a >> (6 * b)) | ((0x7F80 >> b) << !b));
   while(b)
      c += "%" + byte2hex((((a >> (6 * (b=~-b))) | 0x80) & 0xBF));
   return llUnescapeURL(c);
}

#endif
