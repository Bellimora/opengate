#ifndef _INCLUDE_SHRINK_LSL_
#define _INCLUDE_SHRINK_LSL_

// http://sim8846.agni.lindenlab.com:12046/cap/478d2218-c5d1-3a55-ef63-95f06b092cee

#define shrink(s) strreplace(strreplace((s), "http://sim", ""), ".agni.lindenlab.com:12046/cap/", "!");

string unshrink(string s) {
   if (-1 == llSubStringIndex(s, "!")) {
      return s;
   }
   else {
      return "http://sim" + strreplace(s, "!", ".agni.lindenlab.com:12046/cap/");
   }
}

#endif
