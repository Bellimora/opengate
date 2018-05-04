// package snoop

#include "global.h"

integer world_channel = 0x0114A945;
integer debug_channel = 8675;

integer channelof(key id) {
   return (
      (((integer)("0x" + llGetSubString((string)id,0,7))) & 0x7FFFFFFF) |
      0x40000000);
}
list tracking;

default {
   state_entry() {
      llListen(world_channel, "", NULL_KEY, "");
      llListen(debug_channel, "", NULL_KEY, "");
   }
   listen(integer channel, string name, key id, string mesg) {
      if (channel == debug_channel) {
         llOwnerSay(name + " -> " + mesg);
         return;
      }

      if (-1 == llListFindList(tracking, [id])) {
         llListen(channelof(id), "", NULL_KEY, "");
         tracking += id;
      }
      if (-1 == llSubStringIndex(mesg, "DELIVERY")) {
         llDebugSay((string) channel + " :: " + name + " :: " + mesg);
      }
   }
   on_rez(integer unused_param) {
      llResetScript();
   }
}
