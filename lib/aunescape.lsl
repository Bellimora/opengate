#ifndef _INCLUDE_AUNESCAPE_LSL_
#define _INCLUDE_AUNESCAPE_LSL_

#include "constalphas.lsl"
#include "constsymbols.lsl"
#include "unicode2utf8.lsl"

string aunescape(string s) {
   integer k;

   s = llToLower(s);

   for (k = 0; -1 != llSubStringIndex(s, "\\") && k < llStringLength(constsymbols); k++) {
      string letter = llGetSubString(constalphas, k, k);
      string symbol = llGetSubString(constsymbols, k, k);

      // s = llDumpList2String(llParseStringKeepNulls(s, [ "\\"+letter ], []), symbol);
      s = strreplace(s, "\\"+letter, symbol);
   }

   k = llSubStringIndex(s, "u+");
   while (k != -1) {
      string hex = llGetSubString(s, k+2, k+5);
      string r = unicode2utf8((integer)("0x"+hex));
      if (llStringLength(r)) {
         s = strreplace(s, "u+"+hex, r);
         k = llSubStringIndex(s, "u+");
      }
      else {
         k = -1;
      }
   }

   if (llSubStringIndex(s, "~") == 0) {
      for (k = 0; k < llStringLength(constsymbols); k++) {
         string letter = llGetSubString(constalphas, k, k);
         string symbol = llGetSubString(constsymbols, k, k);

         // s = llDumpList2String(llParseStringKeepNulls(s, [ letter ], []), symbol);
         s = strreplace(s, letter, symbol);
      }
      s = llGetSubString(s, 1, -1);
   }

   return s;
}

#endif
