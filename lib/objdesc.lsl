#ifndef _INCLUDE_OBJDESC_LSL_
#define _INCLUDE_OBJDESC_LSL_

string my_llGetObjectDesc() {
   integer counter = 5;
   string ret = llGetObjectDesc();

   while (ret == "(Waiting)" && counter) {
      counter--;
      llSleep(.05);
      ret = llGetObjectDesc();
   }

   return ret;
}
#define llGetObjectDesc my_llGetObjectDesc

#endif
