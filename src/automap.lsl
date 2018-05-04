// This script was loosely based on the original works of
// Peter Lameth and Kegan Loon.
//
// Thanks to Zachary Carter for his interest in making sure
// the Open Gate Network would interoperate with other networks.

#include "global.h"
#include "objname.lsl"
#include "objdesc.lsl"

#define RANDOMCHANNEL (65536 + (integer)llFrand(65536))

integer listen_channel = -900000;
list listen_names = [ "Event Horizon", "_Event Horizon" ];

integer radio_channel = 0;

integer lastmap = 0;
integer MAPDELAY = 7;

string wormhole_region;
vector wormhole_global;
vector wormhole_pos;
vector wormhole_lookat;
rotation wormhole_rot;

key handle;
integer rlv_handle;
integer rlv_start;
integer rlv_channel;
integer use_tpto = FALSE;
integer use_setrot = FALSE;
integer use_teleport = FALSE;

integer request_countdown = 2;

integer get_channel() {
   integer i;

   i = llSubStringIndex(llGetObjectDesc(), "{radio:");
   if (i != -1) {
      i += llStringLength("{radio:");
      return (integer) llGetSubString(llGetObjectDesc(), i, -1);
   }
   return 0;
}

void init_radio() {
   radio_channel = get_channel();
   if (radio_channel != 0) {
      llListen(radio_channel, "", llGetOwner(), "");
      llSetText("radio:"+(string)radio_channel, <1.0,1.0,1.0>, 1.0);
   }
   else {
      llSetText("", <1.0,1.0,1.0>, 1.0);
   }
}

default {
   state_entry() {
      integer i;

      init_radio();

      for (i = 0; i < llGetListLength(listen_names); i++) {
         llListen(listen_channel, llList2String(listen_names, i), NULL_KEY, "");
      }

      llListen(RADIONUM, "", NULL_KEY, "");

      llSetTimerEvent(3.0);

      rlv_start = (integer) llGetUnixTime();
      rlv_channel = RANDOMCHANNEL;
      rlv_handle = llListen(rlv_channel, "", llGetOwner(), "");
      llOwnerSay("Checking rlv version");
      llOwnerSay("@versionnum="+(string)rlv_channel);
   }

   on_rez(integer unused_param) {
      llResetScript();
   }

   run_time_permissions(integer perm) {
      // Not a big deal if they say no, we'll just give them the map instead
      if (perm & PERMISSION_TELEPORT) {
         use_teleport = TRUE;
      }
      if (perm & PERMISSION_TAKE_CONTROLS) {
         // http://wiki.secondlife.com/wiki/LlTakeControls says:
         //
         // There appears to be no penalty for using (accept = TRUE,
         // pass_on = TRUE) when there is no control event in the script
         // (such as is used in AO's to ensure they work on no_script land)
         llTakeControls(CONTROL_FWD, TRUE, TRUE);
      }
   }

   listen(integer channel, string name, key id, string message) {
      if (channel == listen_channel) {
         list parse = llParseString2List(message, ["|"] ,[]);
         if(llList2String(parse, 0) == "map") {
            key k = (key) llList2String(parse, 1);
            if(k == llGetOwner()) {
               string region = llList2String(parse, 2);
               vector pos = (vector)llList2String(parse, 3);
               vector lookat = pos;
               if (llGetListLength(parse) > 4) {
                  lookat = pos + 10.0 * llRot2Up((rotation) llList2String(parse,4));
               }
               integer now = llGetUnixTime();
               if (now - lastmap > MAPDELAY) {
                  llSleep(0.5); // let them walk THROUGH the horizon...
                  if (use_tpto || use_teleport) {
                     // use_tpto: CoolViewer, Restrained Life, possibly others
                     // use_teleport: newer viewers, newer SL, and user has allowed permissions
                     handle = llRequestSimulatorData (region, DATA_SIM_POS);
                  }
                  else {
                     // default LL viewer
                     llMapDestination(region, pos, lookat);
                     llSleep(0.5); // https://jira.secondlife.com/browse/VWR-26442 recommends sleep here
                     llMapDestination(region, pos, lookat); // workaround SL bug
                  }
                  wormhole_region = region;
                  wormhole_pos = pos;
                  wormhole_lookat = lookat;
                  wormhole_rot = (rotation) llList2String(parse, 4);
                  lastmap = now;
               }
            }
         }
      }
      else if (channel == radio_channel) {
         llRegionSay(RADIONUM, 
            llDumpList2String([llEscapeURL(name), id, radio_channel, llEscapeURL(message)], "|"));
      }
      else if (channel == RADIONUM) {
         list l = llParseString2List(message, ["|"], []);
         // via wormhole
         if ((integer)llList2String(l, 4) == radio_channel) {
            string objectname = llGetObjectName();
            llSetObjectName(llUnescapeURL(llList2String(l, 2)) + " (via radio)");
            llOwnerSay(llUnescapeURL(llList2String(l,5)));
            llSetObjectName(objectname);
         }
         // same sim
         if ((integer)llList2String(l, 2) == radio_channel) {
            string objectname = llGetObjectName();
            llSetObjectName(llUnescapeURL(llList2String(l, 0)) + " (via radio)");
            llOwnerSay(llUnescapeURL(llList2String(l,3)));
            llSetObjectName(objectname);
         }
      }
      else if (channel == rlv_channel) {
         llOwnerSay("rlv: " + message);
         llListenRemove(rlv_channel);
         rlv_start = 0;
         if ((integer) message >= 1120000) {
            use_tpto = TRUE;
         }
         if ((integer) message >= 1170000) {
            use_setrot = TRUE;
         }
      }
   }

   timer() {
      if (radio_channel != get_channel()) {
         llResetScript();
      }
      if (rlv_start != 0) {
         if ((llGetUnixTime() - rlv_start) > 30) {
            rlv_start = 0;
            llListenRemove(rlv_handle);
            llOwnerSay("rlv: not detected");
         }
      }
      if (request_countdown) {
         request_countdown--;
         if (!request_countdown) {
            llRequestPermissions(llGetOwner(), PERMISSION_TELEPORT | PERMISSION_TAKE_CONTROLS);
         }
      }
   }

   dataserver(key qid, string data) {
      if (qid == handle) {
         vector pos = (vector) data;
         if (use_tpto) {
            pos = pos + wormhole_pos;
            string pos_str = (string)((integer)pos.x) + "/" +
               (string)((integer)pos.y) + "/" +
               (string)((integer)pos.z);
            llOwnerSay("@tpto:" + pos_str + "=force");
         }
         else if (use_teleport) {
            wormhole_global = pos;
            llTeleportAgentGlobalCoords(llGetOwner(), wormhole_global, wormhole_pos, wormhole_lookat );
         }
         else {
            // this should never happen
         }
      }
   }

   touch_start(integer unused_num) {
      // Occasionally these become prim litter.  We avoid that here.
      if (llGetAttached() == 0) {
         llDie();
      }
   }

   changed(integer change) {
      if (change & CHANGED_TELEPORT) {
         if (use_setrot && llGetRegionName() == wormhole_region) {
               // Ugh.  Maybe we got there.  Maybe we're facing the right way.  Let's find out.
               vector here = llGetPos();
               vector there;

               if (llVecMag(here - wormhole_pos) < 4.0) {
                  // close enough
                  there = wormhole_lookat;
               }
               else {
                  // missed it for some reason
                  // look towards the gate!
                  there = wormhole_pos;
               }

               there = there - here;
               float theta = llAtan2(there.x, there.y); // stupid rlv rotates coordinate systems.
               llOwnerSay("@setrot:" + (string) theta + "=force");
         }

         // Fryke Bloch thought this would be a good idea...
         // we MUST do it here, as it is WAY too hard to do in the gate...
         if (hasflag("push")) {
            if (llToLower(llGetRegionName()) == llToLower(wormhole_region)) {
               if (llVecMag(llGetPos() - wormhole_pos) < 1.5) {
                  llOwnerSay("close, pushing");
                  llPushObject(llGetOwner(),
                        10.0 * (wormhole_lookat - llGetPos()),
                        ZERO_VECTOR,
                        TRUE);
               }
            }
         }

         wormhole_region = "";  // regardless of what happened, clear
      }
   }
}
