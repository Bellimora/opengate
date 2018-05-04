#ifndef _INCLUDE_SETFLAGVALUE_LSL_
#define _INCLUDE_SETFLAGVALUE_LSL_

#include "objname.lsl"
#include "objdesc.lsl"
#include "trim.lsl"

void setflagvalue(string flagname, string flagvalue) {
   string name;
   string desc;
   integer i;
   string left;
   string right;

   name = "   " + llGetObjectName() + "   ";
   i = llSubStringIndex(name, "{" + flagname + ":");
   if (i != -1) {
      left = llGetSubString(name, 0, i - 1);
      right = llGetSubString(name, i, -1);
      i = llSubStringIndex(right, "}");
      if (i != -1) {
         right = llGetSubString(right, i + 1, -1);
         name = left+right;
         llSetObjectName(trim(name));
      }
   }

   desc = "   " + llGetObjectDesc() + "   ";
   i = llSubStringIndex(desc, "{" + flagname + ":");
   if (i != -1) {
      left = llGetSubString(desc, 0, i - 1);
      right = llGetSubString(desc, i, -1);
      i = llSubStringIndex(right, "}");
      if (i != -1) {
         right = llGetSubString(right, i + 1, -1);
         desc = left+right;
         llSetObjectDesc(trim(desc));
      }
   }

   llSetObjectDesc(llGetObjectDesc() + "{" + flagname + ":" + flagvalue + "}");
}

#endif
