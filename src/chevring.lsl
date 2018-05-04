#include "global.h"
#include "objdesc.lsl"

// 0 front
// 1 back
// 2 inner
// 3 outer
// 4 chevron_unlit
// 5 chevron_lit,
// 6 color
// 7 alpha
// 8 bump
// 9 shiny
// 10 glow
// 11 fullbright
// 12 chevsize
// 13 chevrot
// 14 chevsculpt
// 15 chev (bitmask)

list l;
integer initlzd = 0;
list chevnums;

void chev(integer x) {
   integer i;

   for (i = 0; i < 9; i++) {
      if (x & (1 << i)) {
         llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i),
            [PRIM_TEXTURE, 0, llList2String(l,5), <1,1,0>, ZERO_VECTOR, 0.0]);
      }
      else {
         llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i),
            [PRIM_TEXTURE, 0, llList2String(l,4), <1,1,0>, ZERO_VECTOR, 0.0]);
      }
   }
}

void init() {
   llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_COLOR, ALL_SIDES, (vector) llList2String(l,6), (float) llList2String(l,7) ]);

   integer i;
   rotation top_block_rot;
   rotation stepwise_rot;
   rotation pre = llGetRot();
   llSetLinkPrimitiveParamsFast(1, [ PRIM_ROTATION, ZERO_ROTATION ]);
   for (i = 0; i < 9; i++) {
      top_block_rot = llEuler2Rot((vector) llList2String(l,13) * DEG_TO_RAD);
      stepwise_rot = llEuler2Rot(<0,0,i*360/9> * DEG_TO_RAD);

      llSetLinkPrimitiveParamsFast(10-i, [ PRIM_ROTATION, top_block_rot / stepwise_rot ]);
   }
   llSetLinkPrimitiveParamsFast(1, [ PRIM_ROTATION, pre ]);

   for (i = 0; i < 9; i++) {
      llSetLinkPrimitiveParamsFast(i + 2, [ PRIM_TYPE, PRIM_TYPE_SCULPT, llList2String(l,14), PRIM_SCULPT_TYPE_SPHERE]);
   }

   llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_BUMP_SHINY, ALL_SIDES, (integer)llList2String(l,9), (integer)llList2String(l,8) ]);
   llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_GLOW, ALL_SIDES, (float) llList2String(l,10) ]);
   llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_FULLBRIGHT, ALL_SIDES, (integer) llList2String(l,11) ]);

   for (i = 0; i < 9; i++) {
      llSetLinkPrimitiveParamsFast(2 + i, [ PRIM_SIZE, (vector) llList2String(l,12) ]);
   }

   llSleep(2.0);

   llSetLinkPrimitiveParamsFast(1, [PRIM_TEXTURE, 0, llList2String(l,0), <1,1,0>, ZERO_VECTOR, 0.0]);
   llSetLinkPrimitiveParamsFast(1, [PRIM_TEXTURE, 3, llList2String(l,1), <1,1,0>, ZERO_VECTOR, 0.0]);
   llSetLinkPrimitiveParamsFast(1, [PRIM_TEXTURE, 2, llList2String(l,2), <83.117,1,0>, ZERO_VECTOR, 0.0]);
   llSetLinkPrimitiveParamsFast(1, [PRIM_TEXTURE, 1, llList2String(l,3), <64,1,0>, ZERO_VECTOR, 0.0]);

   chev ((integer) llList2String(l, 15));

   initlzd = 1;
}

default {
   state_entry() {
      llSetTouchText("Help");

      if ((integer)llGetObjectDesc()) {
         llListen(918008, "", NULL_KEY, "");
      }
      else {
         llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXTURE, ALL_SIDES, "bd7d7770-39c2-d4c8-e371-0342ecf20921", <1,1,0>, ZERO_VECTOR, 0.0]);
      }
      integer i;
      integer j;
      for (i = 1; i <= 9; i++) {
         for (j = 1; j <= llGetNumberOfPrims(); j++) {
            if (llGetLinkName(j) == (string) i) {
               chevnums = chevnums + [ j ];
            }
         }
      }
   }

   on_rez(integer param) {
      llSetObjectDesc((string)param);
      llResetScript();
   }

   listen(integer unused_chan, string unused_name, key unused_id, string mesg) {
      if (!initlzd && -1 != llSubStringIndex(mesg, "|")) {
         l = llParseString2List(mesg, ["|"], []);
         init();
      }
      else if (initlzd && -1 == llSubStringIndex(mesg, "|")) {
         chev((integer) mesg);
      }
   }

   touch_start(integer num) {
      integer i;
      for (i = 0; i < num; i++) {
         llSay(124, llDetectedKey(i));
      }
   }
}
