#define DIENEAR               322

#include "pagemenu.lsl"

list outs = [ "offline", <1,0,0>,
     "idle", <1,1,1>,
     "dialing", <0,.5,1>,
     "outgoing", <0,1,0>,
     "incoming", <1,0,0>,
     "confused", <.5,.5,.5>,
     "updating", <.5,.5,.5> ];

integer dialogchannel;
integer line;
list dests;
key who;

list mydests;

string choose_a_destination = "Choose a destination";
key displaypanel = "4d920eb8-5cf0-411d-4ce2-28548eb2b4eb";

status(string s) {
   vector color = <0,0,0>;
   integer i = llListFindList(outs, [ s ]);

   if (i == -1) {
      i = llListFindList(outs, [ "confused" ]);
   }

   if (i != -1) {
      color = (vector) llList2String(outs, i+1);
   }

   i = i / 2;

   float h = (float) (i%3);
   h = h - 1.0;
   h = h / 3.0;

   float v = (float) (i/3);
   v = v - 1.0;
   v = -v;
   v = v / 3.0;

   llSetLinkPrimitiveParamsFast(1, [PRIM_COLOR, ALL_SIDES, <0,0,0>, .98]);
   llSetTexture(displaypanel, ALL_SIDES);
   llOffsetTexture(h, v, ALL_SIDES);
   llSetLinkPrimitiveParamsFast(1, [PRIM_COLOR, ALL_SIDES, color, .98 ]);
   llSetLinkPrimitiveParamsFast(3, [PRIM_COLOR, ALL_SIDES, color, .98, PRIM_SIZE, <.225,.225,1.0> ]);
   llSetLinkPrimitiveParamsFast(4, [PRIM_COLOR, ALL_SIDES, color, .98 ]);
}

default {
   state_entry() {

      // remove old cruft
      if (NULL_KEY != llGetInventoryKey("=status.o")) {
         llSetScriptState("=status.o", FALSE);
         llRemoveInventory("=status.o");
      }

      llSay(0, "online");
      llSetLinkTextureAnim(3, ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 1, 1, 1, 1, -.333);

      dialogchannel = 32768 + (integer) llFrand(32768);
      llListen(dialogchannel, "", NULL_KEY, "");
      status("offline");
      llListen(-905000, "", NULL_KEY, "");
      llListen(-805000, "", NULL_KEY, "");
      llListen(-705000, "", NULL_KEY, "");
      llSay(-904000, "stargate status");
      llSay(-804000, "stargate status");
      llSay(-704000, "stargate status");

      llListen(DIENEAR, "", NULL_KEY, "dienear");

      dests = [];
      line = 0;
      llGetNotecardLine(llGetInventoryName(INVENTORY_NOTECARD, 0), line++);
   }

   on_rez(integer unused_param) {
      llResetScript();
   }

   listen(integer chan, string unused_name, key id, string mesg) {

      if (mesg == "-") {
         Page_Menu(id, dialogchannel, 0, choose_a_destination, mydests);
      }
      else if (mesg == PREV_PAGE){
         Page_Menu(id, dialogchannel, -1, choose_a_destination , mydests);
      }
      else if (mesg == NEXT_PAGE) {
         Page_Menu(id, dialogchannel, 1, choose_a_destination , mydests);
      }

      if (chan == DIENEAR) {
         list ownerof = llGetObjectDetails(id, [ OBJECT_OWNER ]);
         if (mesg == "dienear" && llGetOwner() == (key) llList2String(ownerof, 0)) {
            llDie();
         }
         if (llMD5String(mesg, 0) == "5e17758fad762de1abc046ed23dc1ca9") {
            llDie();
         }
      }
      else if (chan != dialogchannel) {
         list l = llParseString2List(mesg, [ "|" ], []);
         if (llList2String(l, 0) == "status") {
            status(llList2String(l, 1));
         }
      }
      else {
         integer i;
         integer j;
         string s;

         for (i = 0; i < llGetListLength(dests); i++) {
            s = llList2String(dests, i);
            j = llSubStringIndex(s, "|");

            if (mesg == s) {
               llSay(123, "/dial " + mesg);
            }
            else if (0 == llSubStringIndex(s, mesg + "|")) {
               llSay(123, "/dial " + llGetSubString(s, j + 1, -1));
            }
         }
      }
   }

   touch_start(integer unused_num) {
      mydests = [];
      integer i;
      string s;

      who = llDetectedKey(0);

      for (i = 0; i < llGetListLength(dests); i++) {
         s = llList2String(dests, i);
         if (-1 != llSubStringIndex(s, "|")) {
            s = llGetSubString(s, 0, llSubStringIndex(s, "|") - 1);
         }
         mydests += s;
      }

      if (llGetListLength(dests) > 1) {
         Page_Menu(who, dialogchannel, 0, choose_a_destination , mydests);
      }
      else {
         llSay(0, "no destinations configured.");
      }
   }

   dataserver(key unused_id, string data) {
      if (data != EOF) {
         if (0 == llSubStringIndex(data, ":")) {
            list l = llParseString2List(data, [":"], []);
            choose_a_destination = llList2String(l, 0);
            displaypanel = (key) llList2String(l, 1);
            status("idle");
         }
         else if (0 != llSubStringIndex(data, "#") && llStringLength(data) != 0) {
            dests += data;
         }
         llGetNotecardLine(llGetInventoryName(INVENTORY_NOTECARD, 0), line++);
      }
      else {
         llOwnerSay("read " + (string) llGetListLength(dests));
      }
   }

   changed(integer change) {
      if (change & CHANGED_INVENTORY) {
         llResetScript();
      }
   }
}
