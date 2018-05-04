// phys-ui.lsl

#include "global.h"

#if defined(PHYS_DESTINY) || defined(PHYS_GENERIC)
#include "flip.lsl"
#endif

#define FX_NUM 18008
#define CHEVRING_NUM 918008

#include "k2ss.lsl"
#include "getflagvalue.lsl"

#if defined (PHYS_WARP) || defined (PHYS_ANGLIA) || defined(PHYS_GENERIC) || defined(PHYS_ELDERGLEN)
#include "k2ss.lsl"
integer k2ss_spot;
#endif

#if defined (PHYS_WARP)
list warp_buttons = [
#include "warpbuttons.lsl"
];

list k2ss_buttons = [];
#endif

#if defined(PHYS_SCIFINERD_MESH)
list light_prims = [
12, 2, 8, 19, 25, 27, 21, 13
];
#endif

integer wormhole_state = 0;
list states = [ "idle", "dialing", "outgoing", "incoming" ];
integer notfound = 0;
string iam_id;
integer iam_num;
string iam_region;
vector iam_pos;
rotation iam_rot;
string iam_name;

string last_theme = "(nil)";
key begin_theme_key = NULL_KEY;
key line_theme_key = NULL_KEY;
integer theme_lines = 0;

integer object_rez_say_channel;
string object_rez_say_message;

#if defined(PHYS_GENERIC)
vector chevcolor;
#endif

#if defined(PHYS_SIMPLE) || defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_ANGLIA) || defined(PHYS_GENERIC)
integer dialprim = 1;
#endif

#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
vector color;
float alpha;
integer bump;
integer shiny;
integer fullbright;
float glow;
#endif
#if defined (PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
string chevron_lit;
string chevron_unlit;
#endif
#ifdef PHYS_ONEPRIM
integer chev;
string front;
string back;
string inner;
string outer;
vector chevsize;
vector chevrot;
string chevsculpt;
#endif
string lock_sound;
string fail_sound;

integer countdown = 0;

#ifdef PHYS_ONEPRIM
integer rezcountdown = 0;
#endif

#if !defined(PHYS_SIMPLE) && !defined(PHYS_ONEPRIM)
list chevnums;
#endif

list where = [
   "", ZERO_VECTOR, ZERO_ROTATION, // target
   ZERO_VECTOR, // scale
   "caa9a96f-aa04-80d3-f4a0-95302f29aa41",             // horizon_texture
   "bbf09ea9-a4f7-fc38-59b5-5ea6fbfe56e3",             // particle_texture
   "aa8612fa-79a5-2435-f528-1ca693b87a77",             // woosh_sound
   "3d631945-9625-842f-eeb0-9fe1c64a2897",             // splash_sound
   "a5b93d83-3def-f54a-f7ca-08a78ccbd329",             // loop_sound
   "bbdfbf3c-044c-e04e-7b88-ec426b2c37fa",             // theme_hsoow_sound
   "dcab6cc4-172f-e30d-b1d0-f558446f20d4",             // theme_collapse
   "6 6 0 36 10",                                      // horizon_animation
   "cylinder"                                          // shape
];

void emit_status() {
      llSay(-905000, "status|"+llList2String(states, wormhole_state));
      //llSay(-805000, "status|"+llList2String(states, wormhole_state));
      //llSay(-705000, "status|"+llList2String(states, wormhole_state));
}

void dial(float dir) {

#if defined(PHYS_SIMPLE) || defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_ANGLIA) || defined(PHYS_GENERIC)
   llSetLinkTextureAnim(dialprim, ANIM_ON | ROTATE | SMOOTH | LOOP, ALL_SIDES,
         0, 0, 0, TWO_PI, dir * TWO_PI/2.8/3); // TODO why not 3.0???
#endif 

#if defined(PHYS_DESTINY)
   if (dir) {
      llTargetOmega(llRot2Up(llGetRot()), 1.0, 10.0);
   }
   else {
      llTargetOmega(ZERO_VECTOR, 0.0, 10.0);
   }
#endif

#if defined(PHYS_SUPER) || defined(PHYS_WARP) || defined(PHYS_ELDERGLEN)
   // meh, avoid lslint unused variable warning
   dir *= 2;
#endif
   
#if defined(PHYS_SCIFINERD_MESH)
   if (dir) {
      llSetLinkPrimitiveParams(6, [ PRIM_OMEGA, dir * -llRot2Fwd(ZERO_ROTATION), 1.0, 10.0 ]);
   }
   else {
      llSetLinkPrimitiveParams(6, [ PRIM_OMEGA, ZERO_VECTOR, 0.0, 10.0 ]);
   }
#endif

}

void light() {

#ifdef PHYS_SIMPLE
   llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_GLOW, ALL_SIDES, 0.1, PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
#endif

#ifdef PHYS_ONEPRIM
   chev = 511;
   llSay(CHEVRING_NUM, (string) chev);
#endif

#ifdef PHYS_ELEVEN
   integer i;
   for (i = 3; i < 12; i++) {
      llSetLinkPrimitiveParamsFast(i, [PRIM_TEXTURE, 0, chevron_lit, <1,1,0>, ZERO_VECTOR, 0.0]);
   }
#endif

#if defined(PHYS_WARP)
   integer i;
   for (i = 0; i < 9; i++) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums,i),
            [ PRIM_TEXTURE, 0, llList2String(k2ss_buttons,i), <1,1,0>, ZERO_VECTOR, 0.0,
            PRIM_TEXTURE, 2, "a9aa021e-3fb9-002e-18cd-ea623382956e", <1,1,0>, ZERO_VECTOR, 0.0,
            PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0 ]); 
   }
#endif 

#if defined(PHYS_DESTINY)
   llSetLinkPrimitiveParamsFast(11, [ PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 1.0 ]);
   llSetLinkPrimitiveParamsFast(2, [ PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 1.0 ]);
#endif

#ifdef PHYS_SUPER
   integer max = llGetNumberOfPrims();
   integer i;
   integer j;

   for (i = 2; i <= max; i++) {
      if (i == max) {
         j = 2;
      }
      else {
         j = i + 1;
      }
      llLinkParticleSystem(i, [
            PSYS_PART_FLAGS, PSYS_PART_TARGET_POS_MASK | PSYS_PART_EMISSIVE_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK,
            PSYS_SRC_TARGET_KEY, llGetLinkKey(j),
            PSYS_PART_START_COLOR, <103,183,248> / 255.0,
            PSYS_PART_START_SCALE, <1.5,1.5,0>,
            PSYS_SRC_BURST_RATE, 1.5,
            PSYS_SRC_BURST_PART_COUNT, 1,
            PSYS_SRC_TEXTURE, "f8e2c2f0-7d5e-bb9a-68d0-7a3e87984784"
            ]);
   }
#endif

#ifdef PHYS_GENERIC
   integer max = llGetListLength(chevnums);
   integer i;
   for (i = 0; i < max; i++) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i), [
            PRIM_COLOR, ALL_SIDES, chevcolor * 2.5, 0.98,
            PRIM_FULLBRIGHT, ALL_SIDES, 1,
            PRIM_GLOW, ALL_SIDES, 0.05
            ]);
   }
#endif

#ifdef PHYS_ELDERGLEN
   integer max = llGetListLength(chevnums);
   integer i;
   for (i = 0; i < max; i++) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i), [
            PRIM_FULLBRIGHT, ALL_SIDES, 1,
            PRIM_GLOW, ALL_SIDES, 0.03
            ]);
   }
#endif

#ifdef PHYS_SCIFINERD_MESH
   integer max = llGetListLength(light_prims);
   integer i;
   for (i = 0; i < max; i++) {
      llSetLinkPrimitiveParamsFast(llList2Integer(light_prims, i),
            [PRIM_GLOW, ALL_SIDES, 0.2, PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
   }
#endif
}

void unlight() {

#if defined(PHYS_SIMPLE) || defined(PHYS_SCIFINERD_MESH)
   llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_GLOW, ALL_SIDES, 0.0, PRIM_FULLBRIGHT, ALL_SIDES, FALSE]);
#endif

#ifdef PHYS_ONEPRIM
   chev = 0;
   llSay(CHEVRING_NUM, (string) chev);
#endif

#ifdef PHYS_ELEVEN
   integer i;
   for (i = 3; i < 12; i++) {
      llSetLinkPrimitiveParamsFast(i, [PRIM_TEXTURE, 0, chevron_unlit, <1,1,0>, ZERO_VECTOR, 0.0]);
   }
#endif

#ifdef PHYS_WARP
   llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [
         PRIM_TEXTURE, 0, "2a1e732d-59ba-ff26-bbab-283ad1433760", <1,1,0>, ZERO_VECTOR, 0.0,
         PRIM_TEXTURE, 2, "2a1e732d-59ba-ff26-bbab-283ad1433760", <1,1,0>, ZERO_VECTOR, 0.0,
         PRIM_COLOR, ALL_SIDES, <0,0,0>, 1.0,
         PRIM_COLOR, 0, <1,1,1>, 1.0,
         PRIM_COLOR, 2, <1,1,1>, 1.0 ]); 
   llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_COLOR, ALL_SIDES, <0,0,0>, 1.0 ]);
#endif

#ifdef PHYS_ANGLIA
   integer i;
   for (i = 0; i < 7; i++) {
      llSetLinkPrimitiveParamsFast((integer)llList2String(chevnums, i),
            [ PRIM_TEXTURE, 3, "69b0b7f1-c72e-dbcb-fed8-8782700acc55",
            <0.15, 0.15, 0.0>, <0.4, -0.4, 0.0>, 0.0 ]);
   }
#endif

#ifdef PHYS_DESTINY
   llSetLinkPrimitiveParamsFast(11, [ PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0 ]);
   llSetLinkPrimitiveParamsFast(2, [ PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0 ]);
#endif

#ifdef PHYS_SUPER
   llLinkParticleSystem(LINK_SET, []);
#endif

#ifdef PHYS_GENERIC
   integer max = llGetListLength(chevnums);
   integer i;
   for (i = 0; i < max; i++) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i), [
            PRIM_COLOR, ALL_SIDES, chevcolor, 0.98,
            PRIM_FULLBRIGHT, ALL_SIDES, 0,
            PRIM_GLOW, ALL_SIDES, 0.0
            ]);
   }
#endif

#ifdef PHYS_ELDERGLEN
   integer max = llGetListLength(chevnums);
   integer i;
   for (i = 0; i < max; i++) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, i), [
            PRIM_FULLBRIGHT, ALL_SIDES, 0,
            PRIM_GLOW, ALL_SIDES, 0.0
            ]);
   }
#endif
}

void rez_horizon() {
   integer c = (integer) llFrand(4096) + 4096;

   light();
   dial(0.0);

   vector size = llGetScale();

#if defined(PHYS_SCIFINERD_MESH)
   size.x = size.y * 8.0 / 9.94;
   size.y = size.x;
#endif

   where = llListReplaceList(where, [ size ], 3, 3);

   if (wormhole_state == 2) {
      where = llListReplaceList(where, [ iam_region, iam_pos, iam_rot ], 0, 2);
   }
   else {
      where = llListReplaceList(where, [ "", ZERO_VECTOR, ZERO_ROTATION ], 0, 2);
   }

#if defined(PHYS_SUPER)
   where = llListReplaceList(where, [ <40,40,.2> ], 3, 3);
   // where = llListReplaceList(where, [ "mega" ], 13, 13);
#endif

   string s = llEscapeURL(llDumpList2String(where, ","));

#if defined(PHYS_SCIFINERD_MESH)
   rotation rot = llAxes2Rot(-llRot2Up(llGetRot()), llRot2Left(llGetRot()), llRot2Fwd(llGetRot()));
   llRezObject(">horizon", llGetPos(), ZERO_VECTOR, rot, c);
#else
   llRezObject(">horizon", llGetPos(), ZERO_VECTOR, llGetRot(), c);
#endif

   object_rez_say_channel = c;
   object_rez_say_message = s;
}

default {
   state_entry() {
#if defined(PHYS_ONEPRIM)
   llSetPrimitiveParams([PRIM_SIZE, <5.45, 5.45, .3>]); // bunch of savages resizing things!
#endif

#if defined(PHYS_DESTINY) || defined(PHYS_GENERIC)
      doflip();
#endif
      llSetTouchText("Help");
      send("me", "preload", "texture", "3124ac03-baac-e08e-cded-063fade39e21");
      send("me", "preload", "texture", "caa9a96f-aa04-80d3-f4a0-95302f29aa41");
      send("me", "preload", "texture", "dcab6cc4-172f-e30d-b1d0-f558446f20d4");
      llListen(-904000, "", NULL_KEY, "stargate status");
      //llListen(-804000, "", NULL_KEY, "stargate status");
      //llListen(-704000, "", NULL_KEY, "stargate status");
      llSetTimerEvent(1.0);

#if !defined(PHYS_SIMPLE) && !defined(PHYS_ONEPRIM)
      integer i;
      integer j;
      for (i = 1; i <= 9; i++) {
         for (j = 1; j <= llGetNumberOfPrims(); j++) {
            list l = llGetLinkPrimitiveParams(j, [ PRIM_DESC ]);
            if (llGetLinkName(j) == (string) i || llList2String(l, 0) == (string) i) {
               chevnums = chevnums + [ j ];
            }
#if defined(PHYS_SIMPLE) || defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_ANGLIA) || defined(PHYS_GENERIC)
            if (llGetLinkName(j) == "dial") {
               dialprim = j;
            }
#endif
         }
      }
#endif

#if defined(PHYS_GENERIC)
      list l = llGetLinkPrimitiveParams((integer) llList2String(chevnums, 0), [ PRIM_COLOR, 0 ]);
      chevcolor = (vector) llList2String(l, 0);
#endif
   }

   listen(integer unused_chan, string unused_name, key unused_id, string unused_mesg) {
      emit_status();
   }

   timer() {

      string theme;
      theme = getflagvalue("theme");
      if (theme == "") {
         theme = "milkyway";
      }
      if (theme != last_theme) {
         if (llGetInventoryKey("@theme:" + theme) != NULL_KEY) {
            last_theme = theme;
            begin_theme_key = llGetNumberOfNotecardLines("@theme:" + theme);
         }
      }

#ifdef PHYS_ONEPRIM
      if (rezcountdown) {
         rezcountdown--;
      }
      if (rezcountdown == 43) {
         llSay(CHEVRING_NUM, llDumpList2String([
            front, back, inner, outer, chevron_unlit, chevron_lit,
            color, alpha, bump, shiny, glow, fullbright, chevsize, chevrot, chevsculpt, chev
            ], "|"));
      }
      if (!rezcountdown) {
         llRezObject(">chevring", llGetPos() + -.01 * llRot2Up(llGetRot()), ZERO_VECTOR, llGetRot(), 1);
         rezcountdown = 45;
      }
#endif

      if (countdown) {

         countdown--;

         if (wormhole_state == 1) {
            if (countdown == 1) {
               dial(0.0);
            }
            else if ((countdown % 4) == 1) {
               dial(-1.0);
            }
            else if ((countdown % 4) == 3) {
               dial(1.0);
            }
            if ((countdown % 2) == 1) {
               llTriggerSound(lock_sound, 1.0);

#ifdef PHYS_ONEPRIM
               chev = (1 << (1 + 6 - (countdown / 2))) - 1;
               llSay(CHEVRING_NUM, (string) chev);
#endif

#ifdef PHYS_ELEVEN
               llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums,6 - (countdown/2)), [PRIM_TEXTURE, 0, chevron_lit, <1,1,0>, ZERO_VECTOR, 0.0]);
#endif

#if defined(PHYS_WARP) || defined(PHYS_ANGLIA) || defined(PHYS_GENERIC) || defined(PHYS_ELDERGLEN)
               k2ss_spot = 6 - (countdown/2);
#endif

#if defined(PHYS_WARP)
               llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums,k2ss_spot),
                     [ PRIM_TEXTURE, 0, llList2String(k2ss_buttons,k2ss_spot), <1,1,0>, ZERO_VECTOR, 0.0,
                     PRIM_TEXTURE, 2, "a9aa021e-3fb9-002e-18cd-ea623382956e", <1,1,0>, ZERO_VECTOR, 0.0,
                     PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0 ]); 
#endif 

#ifdef PHYS_GENERIC
   integer step = llGetListLength(chevnums) / 9;
   integer i;
   integer n;
   for (i = 0; i < step; i++) {
      n = k2ss_spot * step + i;
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, n), [
            PRIM_COLOR, ALL_SIDES, chevcolor * 2.5, 0.98,
            PRIM_FULLBRIGHT, ALL_SIDES, 1,
            PRIM_GLOW, ALL_SIDES, 0.05
            ]);
   }
#endif

#ifdef PHYS_ELDERGLEN
   if (k2ss_spot < llGetListLength(chevnums)) {
      llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums, k2ss_spot), [
            PRIM_FULLBRIGHT, ALL_SIDES, 1,
            PRIM_GLOW, ALL_SIDES, 0.05
            ]);
   }
#endif

#if defined(PHYS_ANGLIA)
               if (llStringLength(iam_id)) {
                  integer n;
                  integer i;
                  for (i = 0; i <= k2ss_spot; i++) {
                     n = llSubStringIndex(constsymbols, llGetSubString(k2ss(iam_id), i, i));
                     llSetLinkPrimitiveParamsFast((integer)llList2String(chevnums, i),
                           [ PRIM_TEXTURE, 3, "69b0b7f1-c72e-dbcb-fed8-8782700acc55",
                           <0.15, 0.15, 0.0>, <(n % 5) * .2 - 0.4, (n / 5) * -.2 + 0.4, 0.0>, 0.0 ]);
                  }
               }
#endif

#if defined(PHYS_SCIFINERD_MESH)
               integer i = 6 - (countdown/2);
                  llSetLinkPrimitiveParamsFast(llList2Integer(light_prims, i),
                        [PRIM_GLOW, ALL_SIDES, 0.2, PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
#endif
            }
         }

         if (!countdown) {
            if (wormhole_state == 1) {
               if (iam_id == "") { // && notfound > 0) 
                  llSay(0, "Not found");
                  llTriggerSound(fail_sound, 1.0);
                  wormhole_state = 0;
                  emit_status();
                  unlight();
                  dial(0.0);
               }
               else {
                  llSay(0, "Opening to " + k2ss(key_part(iam_id)) + ", '" + iam_name + "' at " + iam_region +
                        "/" + (string)((integer) iam_pos.x) + 
                        "/" + (string)((integer) iam_pos.y) + 
                        "/" + (string)((integer) iam_pos.z));
                  send("me", "opento", iam_id);
                  wormhole_state = 2;
                  emit_status();
                  rez_horizon();
                  llSetTimerEvent(1.0);
                  countdown = 60;
               }
            }
            else {
               unlight();
               dial(0.0);
               wormhole_state = 0;
               emit_status();
            }
         }
      }
   }

   on_rez(integer unused_start_param) {
      llResetScript();
   }

   link_message(integer unused_sender, integer num, string mesg, key id) {
      if (num == MESG_RECV) {
         list pieces = llParseStringKeepNulls(mesg, ["/"], []);
         string arg0 = llList2String(pieces, 0);

#ifdef VDEBUG
         llDebugSay("MESG_RECV '"+arg0+"'");
#endif

         if (arg0 == "verb") {
            if (wormhole_state != 0) {
               llSay(0, "Wait (" + llList2String(states, wormhole_state) + ")");
               return;
            }
            send("me", "lookup", llList2String(pieces, 1), hash((string) llFrand(1.0)));
            wormhole_state = 1;
            emit_status();
            notfound = 0;
            iam_id = "";
            iam_num = -1;
            llSetTimerEvent(1.0);
            countdown = 14;
            dial(1.0);
            if (llStringLength(llList2String(pieces, 1))) {
               llSay(0, "Dialing '" + llList2String(pieces, 1) + "'");
            }
            else {
               llSay(0, "Dialing...");
            }
#if defined(PHYS_WARP) || defined(PHYS_ANGLIA)
            k2ss_spot = -1;
#endif
#if defined(PHYS_WARP)
            k2ss_buttons = [
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e",
               "a9aa021e-3fb9-002e-18cd-ea623382956e"
               ];
#endif
         }
         if (arg0 == "iam") {
            if (iam_id == "" || iam_num > (integer) llList2String(pieces, 3)) {
               iam_id = id;
               iam_num = (integer) llList2String(pieces, 3);
               iam_region = llUnescapeURL(llList2String(pieces, 4));
               iam_pos = (vector) llList2String(pieces, 5);
               iam_rot = (rotation) llList2String(pieces, 6);
               iam_name = llUnescapeURL(llList2String(pieces, 7));
#ifdef DEBUG
               if (hasflag("debug")) {
                  llDebugSay("region="+iam_region);
                  llDebugSay("pos="+(string)iam_pos);
                  llDebugSay("rot="+(string)iam_rot);
               }
#endif
#if defined(PHYS_WARP)
               string ss = k2ss(id);
               integer n;
               integer i;
               for (i = 0; i < 7; i++) {
                  n = llSubStringIndex(constsymbols, llGetSubString(ss, i, i));
                  k2ss_buttons = llListReplaceList(k2ss_buttons, [ llList2String(warp_buttons, n) ], i, i);
                  if (i <= k2ss_spot) {
                     llSetLinkPrimitiveParamsFast((integer) llList2String(chevnums,i),
                        [ PRIM_TEXTURE, 0, llList2String(k2ss_buttons,i), <1,1,0>, ZERO_VECTOR, 0.0,
                        PRIM_TEXTURE, 2, "a9aa021e-3fb9-002e-18cd-ea623382956e", <1,1,0>, ZERO_VECTOR, 0.0,
                        PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0 ]); 
                  }
               }
#endif
#if defined(PHYS_ANGLIA)
               // face=3
               // 69b0b7f1-c72e-dbcb-fed8-8782700acc55,<0.150000, 0.150000, 0.000000>,<0.400000, -0.400000, 0.000000>,0.000000

               string ss = k2ss(id);
               integer n;
               integer i;
               for (i = 0; i < 7; i++) {
                  n = llSubStringIndex(constsymbols, llGetSubString(ss, i, i));
                  if (i <= k2ss_spot) {
                     llSetLinkPrimitiveParamsFast((integer)llList2String(chevnums, i),
                           [ PRIM_TEXTURE, 3, "69b0b7f1-c72e-dbcb-fed8-8782700acc55",
                           <0.15, 0.15, 0.0>, <(n % 5) * .2 - 0.4, (n / 5) * -.2 + 0.4, 0.0>, 0.0 ]);
                  }
               }
#endif
            }
         }
         if (arg0 == "notfound") {
            notfound++;
         }
         if (arg0 == "woosh") {
            if (wormhole_state == 0) {
               wormhole_state = 3;
               emit_status();
               rez_horizon();
               llSetTimerEvent(1.0);
               countdown = 60;
            }
#ifdef DEBUG
            else if (hasflag("debug")) {
               llDebugSay("ignoring woosh while in state " + (string) wormhole_state);
            }
#endif
         }
      }
   }

   dataserver(key qid, string data) {
      if (qid == begin_theme_key) {
         theme_lines = (integer) data;
         theme_lines--;
         line_theme_key = llGetNotecardLine("@theme:" + last_theme, theme_lines);
         send("me", "preload", "texture", "clear");
         send("me", "preload", "sound", "clear");
      }
      else if (qid == line_theme_key) {
         list theme_values = llParseString2List(data, [ "=" ], []);
         string name = llList2String(theme_values, 0);
         string value = llList2String(theme_values, 1);

#ifdef DEBUG
         if (hasflag("debug")) {
            llDebugSay("got '"+name+"' = '"+value+"'");
         }
#endif

         //back  key   texture used on back of Stargate
#if defined (PHYS_ELEVEN) || defined (PHYS_ONEPRIM)
         if (name == "back") {
#ifdef PHYS_ELEVEN
            llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, 3, value, <1,1,0>, ZERO_VECTOR, 0.0]);
#endif
#ifdef PHYS_ONEPRIM
            back = value;
#endif
         }
#endif
         //bigchevron_lit key   texture for lit top chevron (DEPRECATED)
         //bigchevron_unlit  key   texture for unlit top chevron (DEPRECATED)
         //bumpshiny   string   bump shiny setting (comma seperated) (see below)
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         if (name == "bumpshiny") {
            list bs = llParseString2List(llToLower(value), [ "," ], []);
            string b = llList2String(bs, 0);
            string s = llList2String(bs, 1);
            list bumps = [ "none", "bright", "dark", "wood", "bark", "bricks", "checker", "concrete",
                 "tile", "stone", "disks", "gravel", "blobs", "siding", "stucco", "suction", "weave" ];
            list shinys = [ "none", "low", "medium", "high" ];
            bump = llListFindList(bumps, [ b ]);
            shiny = llListFindList(shinys, [ s ]);
            llSay(FX_NUM, llDumpList2String([ name, bump, shiny ], "|"));
            if (bump == -1) {
               llSay(0, "WARN: bump '" + b + "' not recognized, choose one of: " + llDumpList2String(bumps, ","));
            }
            else if (shiny == -1) {
               llSay(0, "WARN: shiny '" + s + "' not recognized, choose one of: " + llDumpList2String(shinys, ","));
            }
            else {
               llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_BUMP_SHINY, ALL_SIDES, shiny, bump ]);
            }
         }
#endif
         //chevron_lit key   texture for lit non-top chevron
#if defined (PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
         if (name == "chevron_lit") {
            chevron_lit = value;
            send("me", "preload", "texture", value);
         }
#endif
         //chevron_ring   string   sculpted or flat (DEPRECATED)
         //chevron_rot vector   euler degree rotation of topmost chevron when ring is in <0,0,0> rotation
#if defined (PHYS_ELEVEN) || defined (PHYS_ONEPRIM)
         if (name == "chevron_rot") {
#ifdef PHYS_ELEVEN
            integer i;
            rotation top_block_rot;
            rotation stepwise_rot;
            rotation pre = llGetRot();
            llSetLinkPrimitiveParamsFast(1, [ PRIM_ROTATION, ZERO_ROTATION ]);
            for (i = 0; i < 9; i++) {
               top_block_rot = llEuler2Rot((vector) value * DEG_TO_RAD);
               stepwise_rot = llEuler2Rot(<0,0,i*360/9> * DEG_TO_RAD);

               llSetLinkPrimitiveParamsFast(11-i, [ PRIM_ROTATION, top_block_rot / stepwise_rot ]);
            }
            llSetLinkPrimitiveParamsFast(1, [ PRIM_ROTATION, pre ]);
#endif
#ifdef PHYS_ONEPRIM
            chevrot = (vector) value;
#endif
         }
#endif
         //chevron_sculpt key   sculpt map used for chevrons
#if defined (PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
         if (name == "chevron_sculpt") {
#ifdef PHYS_ELEVEN
            integer i;
            for (i = 3; i < 12; i++) {
               llSetLinkPrimitiveParamsFast(i, [ PRIM_TYPE, PRIM_TYPE_SCULPT, value, PRIM_SCULPT_TYPE_SPHERE]);
            }
#endif
#ifdef PHYS_ONEPRIM
            chevsculpt = value;
#endif
         }
#endif
         //chevron_size   vector   size of chevron prims
#if defined (PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
         if (name == "chevron_size") {
#ifdef PHYS_ELEVEN
            integer i;
            for (i = 3; i < 12; i++) {
               llSetLinkPrimitiveParamsFast(i, [ PRIM_SIZE, (vector) value ]);
            }
#endif
#ifdef PHYS_ONEPRIM
            chevsize = (vector) value;
#endif
         }
#endif
         //chevron_unlit  key   texture for unlit non-top chevrons
#if defined (PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
         if (name == "chevron_unlit") {
            chevron_unlit = value;
#ifdef PHYS_ELEVEN
            integer i;
            for (i = 3; i < 12; i++) {
               llSetLinkPrimitiveParamsFast(i, [PRIM_TEXTURE, 0, value, <1,1,0>, ZERO_VECTOR, 0.0]);
            }
#endif
         }
#endif
         //collapse_texture  key   particle texture for collapsing wormhole
         if (name == "collapse_texture") {
            where = llListReplaceList(where, [ value ], 10, 10);
            send("me", "preload", "texture", value);
         }
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         //coloralpha  rotation <red, green, blue, alpha> setting
         if (name == "coloralpha") {
            rotation coloralpha = (rotation) value;
            color = < coloralpha.x, coloralpha.y, coloralpha.z >;
            alpha = coloralpha.s;
            llSay(FX_NUM, llDumpList2String([ name, color, alpha ], "|"));
            llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_COLOR, ALL_SIDES, color, alpha ]);
         }
#endif
         //dhd   key   texture used for dhd
         if (name == "dhd") {
            llSay(FX_NUM, llDumpList2String([ name, value ], "|"));
         }
         //edge_inner  key   texture used on inner edge of Stargate
#if defined (PHYS_ELEVEN) || defined (PHYS_ONEPRIM)
         if (name == "edge_inner") {
#ifdef PHYS_ELEVEN
            llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, 2, value, <83.117,1,0>, ZERO_VECTOR, 0.0]);
#endif
#ifdef PHYS_ONEPRIM
            inner = value;
#endif
         }
#endif
         //edge_outer  key   texture used on outer edge of Stargate
#if defined (PHYS_ELEVEN) || defined (PHYS_ONEPRIM)
         if (name == "edge_outer") {
#ifdef PHYS_ELEVEN
            llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, 1, value, <64,1,0>, ZERO_VECTOR, 0.0]);
#endif
#ifdef PHYS_ONEPRIM
            outer = value;
#endif
         }
#endif
         //event_horizon  string   hollowsphere or 36frame
         if (name == "event_horizon") {
            where = llListReplaceList(where, [ value ], 12, 12);
         }
         //fail_sound  key   sound used for failed dials
         if (name == "fail_sound") {
            fail_sound = value;
         }
         //front key   texture used on front face of Stargate
#if defined (PHYS_ELEVEN) || defined (PHYS_ONEPRIM)
         if (name == "front") {
#ifdef PHYS_ELEVEN
            llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, 0, value, <1,1,0>, ZERO_VECTOR, 0.0]);
#endif
#ifdef PHYS_ONEPRIM
            front = value;
#endif
         }
#endif
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         //fullbright  integer  1 for fullbright on or 0 for off
         if (name == "fullbright") {
            fullbright = (integer) value;
            llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_FULLBRIGHT, ALL_SIDES, fullbright ]);
            llSay(FX_NUM, llDumpList2String([ name, value ], "|"));
         }
#endif
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         //glow  float glow setting
         if (name == "glow") {
            glow = (float) value;
            llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_GLOW, ALL_SIDES, glow ]);
            llSay(FX_NUM, llDumpList2String([ name, value ], "|"));
         }
#endif
         // horizon  key   texture used for event horizon
         if (name == "horizon") {
            where = llListReplaceList(where, [ value ], 4, 4);
            send("me", "preload", "texture", value);
         }
         //horizon_animation string   parameters passed to llSetTextureAnim
         if (name == "horizon_animation") {
            where = llListReplaceList(where, [ value ], 11, 11);
         }
         //hsoow_sound key   sound used for collapsing wormhole
         if (name == "hsoow_sound") {
            where = llListReplaceList(where, [ value ], 9, 9);
            send("me", "preload", "sound", value);
         }
         //lock_sound  key   sound used for chevron locking
         if (name == "lock_sound") {
            lock_sound = value;
            send("me", "preload", "sound", value);
         }
         //loop_sound  key   sound used while wormhole is open
         if (name == "loop_sound") {
            where = llListReplaceList(where, [ value ], 8, 8);
            send("me", "preload", "sound", value);
         }
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         //material string   stone, metal, glass, wood, flesh, plastic, or rubber
         if (name == "material") {
            list materials = [ "stone", "metal", "glass", "wood", "flesh", "plastic", "rubber", "light" ];
            integer m = llListFindList(materials, [ value ]);
            llSay(FX_NUM, llDumpList2String([ name, m ], "|"));

            if (m == -1) {
               llSay(0, "WARN: material '" + value + "' not recognized, choose one of: " + llDumpList2String(materials, ","));
            }
            else {
               llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_MATERIAL, m ]);
            }
         }
#endif
         //ring  key   texture used on dialing ring
         //ring_static key   texture used on multiprim dialing ring when not moving
#if defined(PHYS_ELEVEN) || defined(PHYS_ONEPRIM)
         if (name == "ring_static" || name == "ring") {
            llSetTexture(value, ALL_SIDES);
         }
#endif
         //splash   key   sound used for avatar colliding with wormhole
         if (name == "splash") {
            where = llListReplaceList(where, [ value ], 7, 7);
            send("me", "preload", "sound", value);
         }
#if defined(PHYS_ONEPRIM) || defined(PHYS_ELEVEN) || defined(PHYS_SIMPLE)
         //texgen   string   default or planar
         if (name == "texgen") {
            value = llToLower(value);
            if (value == "default") {
               llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_TEXGEN, ALL_SIDES, PRIM_TEXGEN_DEFAULT ]);
            }
            else if (value == "planar") {
               llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_TEXGEN, ALL_SIDES, PRIM_TEXGEN_PLANAR ]);
            }
            else {
               llSay(0, "WARN: texgen must be either 'default' of 'planar'");
            }
         }
#endif
         //woosh key   particle texture for opening kawoosh
         if (name == "woosh") {
            where = llListReplaceList(where, [ value ], 5, 5);
            send("me", "preload", "texture", value);
         }
         //woosh_sound key   sound used for wormhole opening
         if (name == "woosh_sound") {
            where = llListReplaceList(where, [ value ], 6, 6);
            send("me", "preload", "sound", value);
         }

         theme_lines--;
         if (theme_lines >= 0) {
            line_theme_key = llGetNotecardLine("@theme:" + last_theme, theme_lines);
         }
         else {
            unlight();
         }
      }
   }

   object_rez(key unused_id) {
      if (object_rez_say_channel != 0) {
         llSay(object_rez_say_channel, object_rez_say_message);
         llSleep(.1);
         llSay(object_rez_say_channel, object_rez_say_message);
         llSleep(.2);
         llSay(object_rez_say_channel, object_rez_say_message);
         llSleep(.3);
         llSay(object_rez_say_channel, object_rez_say_message);
         llSleep(.4);
         llSay(object_rez_say_channel, object_rez_say_message);

         object_rez_say_channel = 0;
      }
   }
}
