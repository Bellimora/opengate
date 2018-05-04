#include "global.h"

#include "constsymbols.lsl"
#include "k2ss.lsl"

#define ADDRDISPNUM        343532
#define DIENEAR 322

#define SYMBOL_TEXTURE "b378d2ed-94d7-a7da-4863-7819fb6e8009"
#define TOTALLYCLEAR "f54a0c32-3cd1-d49a-5b4f-7b792bebc204"

list map = [1,2,3,0,4,5,6];

list warp = [
#include "blackbuttons.lsl"
];

float rot() {
   float ret = 0.0;
   if (hasflag("rot+")) {
      ret = ret + PI/2.0;
   }
   if (hasflag("rot-")) {
      ret = ret - PI/2.0;
   }
   return ret;
}

void single_warp(integer i, string glyph) {
   integer gnum = llSubStringIndex(constsymbols, glyph);

   integer j;
   j = (integer) llList2String(map, i);

   integer k;
   k = (integer) llList2String(map, 6-i);

   llSetLinkPrimitiveParamsFast(j+1,
         [ PRIM_TEXTURE, 0,
         (key)llList2String(warp,gnum),
         <1.0, 1.0, 0.0>, <0.0,0.0,0.0>, 0.0 + rot()]);

   llSetLinkPrimitiveParamsFast(k+1,
         [ PRIM_TEXTURE, 2,
         (key)llList2String(warp,gnum),
         <1.0, 1.0, 0.0>, <0.0,0.0,0.0>, PI + rot()]);
}

void single_old(integer i, string glyph) {
   integer gnum = llSubStringIndex(constsymbols, glyph);
   float h;
   float v;

   integer j;
   j = (integer) llList2String(map, i);

   integer k;
   k = (integer) llList2String(map, 6-i);

   //v = .250 + ((float)(gnum/12)) * .5;
   //h = -.5 + (1.0/24.0) + ((float) (gnum%12)) /12.0;
   v = -.5 + .1 + ((float)(gnum/5)) * .2;
   h = -.5 + .1 + ((float)(gnum%5)) * .2;

   llSetLinkPrimitiveParamsFast(j+1,
         [ PRIM_TEXTURE, 0,
         SYMBOL_TEXTURE,
         <0.2, 0.2, 0.0>, <h,-v,0.0>, 0.0 + rot()]);

   llSetLinkPrimitiveParamsFast(k+1,
         [ PRIM_TEXTURE, 2,
         SYMBOL_TEXTURE,
         <0.2, 0.2, 0.0>, <h,-v,0.0>, PI + rot()]);
}
void single(integer i, string glyph) {
   if (hasflag("warp")) {
      single_warp(i, glyph);
   }
   else {
      single_old(i, glyph);
   }
}

void display(string s) {
   string g;
   integer i;

   llSetLinkPrimitiveParamsFast(LINK_SET,
         [ PRIM_TEXTURE, ALL_SIDES,
         TOTALLYCLEAR,
         <0.0, 0.0, 0.0>, <0.0,0.0,0.0>, 0.0]);

   for (i = 0; i < llStringLength(s); i++) {
      g = llGetSubString(s, i, i);
      single(i, g);
   }
}

default {
   state_entry() {

      // remove old cruft
      if (NULL_KEY != llGetInventoryKey("=addrdisp.o")) {
         llSetScriptState("=addrdisp.o", FALSE);
         llRemoveInventory("=addrdisp.o");
      }

      llSay(0, "online");

      llListen(ADDRDISPNUM, "", NULL_KEY, "pong");
      llListen(DIENEAR, "", NULL_KEY, "dienear");

      llSay(ADDRDISPNUM, "ping");
   }

   touch_start(integer unused_count) {
      llResetScript();
   }

   listen(integer channel, string unused_name, key id, string mesg) {
      if (channel == ADDRDISPNUM) {
         if (mesg == "pong") {
            display(k2ss(id));
         }
         return;
      }
      else if (channel == DIENEAR) {
         list ownerof = llGetObjectDetails(id, [ OBJECT_OWNER ]);
         if (mesg == "dienear" && llGetOwner() == (key) llList2String(ownerof, 0)) {
            llDie();
         }
         if (llMD5String(mesg, 0) == "5e17758fad762de1abc046ed23dc1ca9") {
            llDie();
         }
      }
   }

   on_rez(integer unused_param) {
      llResetScript();
   }
}
