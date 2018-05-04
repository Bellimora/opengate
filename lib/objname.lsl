#ifndef _INCLUDE_OBJNAME_LSL_
#define _INCLUDE_OBJNAME_LSL_

string my_llGetObjectName() {
   integer counter = 5;
   string ret = llGetObjectName();

   while (ret == "(Waiting)" && counter) {
      counter--;
      llSleep(.05);
      ret = llGetObjectName();
   }

   return ret;
}
#define llGetObjectName my_llGetObjectName

#endif
