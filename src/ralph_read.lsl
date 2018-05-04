// This script is named after "ralph the all purpose animal"
// from the film "twice upon a time"

// use this script to read the primitiveparams of an object

#include "safelist.lsl"

// I'm too lazy to go modify my lslint builtins.txt
#define PRIM_SLICE 35

integer num = 0;

string buffer = "";

void say(string s) {
   integer spew = 0;

   if (s != "") {
      buffer = buffer + s + "<";
   }
   else {
      spew = 1;
   }

   if (llStringLength(buffer) > 250) {
      spew = 1;
   }

   if (spew) {
      s = llGetSubString(buffer, 0, 249);
      buffer = llGetSubString(buffer, 250, -1);

      llSay(0, (string) num + "^^^" + s);
      num++;
      llSleep(0.06);
   }
}

integer listeq(list l1, list l2) {
   integer i;
   if (llGetListLength(l1) != llGetListLength(l2)) {
      return 0;
   }
   for (i = 0; i < llGetListLength(l1); i++) {
      if (llGetListEntryType(l1, i) != llGetListEntryType(l2, i)) {
         return 0;
      }
      if (llList2String(l1, i) != llList2String(l2, i)) {
         return 0;
      }
   }
   return 1;
}

default {
   state_entry () {

      integer type1a =
         1 << PRIM_NAME |
         1 << PRIM_DESC |
         1 << PRIM_TYPE |
         1 << PRIM_PHYSICS_SHAPE_TYPE |
         1 << PRIM_MATERIAL |
         1 << PRIM_PHYSICS |
         1 << PRIM_TEMP_ON_REZ |
         1 << PRIM_PHANTOM |
         // 1 << PRIM_POSITION |
         1 << PRIM_ROTATION |
         1 << PRIM_ROT_LOCAL |
         1 << PRIM_SIZE |
         1 << PRIM_TEXT |
         1 << PRIM_FLEXIBLE |
         1 << PRIM_POINT_LIGHT |
         0;

      integer type1b = 
         1 << PRIM_SLICE |
         1 << PRIM_POS_LOCAL |
         1 << PRIM_OMEGA |
         0;

      integer type2 =
         1 << PRIM_TEXTURE |
         1 << PRIM_COLOR |
         1 << PRIM_BUMP_SHINY |
         1 << PRIM_FULLBRIGHT |
         1 << PRIM_TEXGEN |
         1 << PRIM_GLOW |
         0;
      integer i;
      integer j;
      integer k;
      integer n = 0;

      llSay(0, "=== BEGIN ===");
      say(list2safe(["PRIMS", llGetNumberOfPrims()]));

      if (llGetNumberOfPrims() > 1) {
         n = 1;
      }

      for (j = 0; j < llGetNumberOfPrims(); j++) {
         for (i = 0; i < 32; i++) {
            if ((1 << i) & type1a) {
               say(list2safe([ i ] + llGetLinkPrimitiveParams(j+n, [ i ])));
            }
         }
         for (i = 0; i < 32; i++) {
            if ((1 << i) & type1b) {
               if (i+32 != 33 || j+n > 1) { // special case, no pos_local for root
                  say(list2safe([ i+32 ] + llGetLinkPrimitiveParams(j+n, [ i+32 ])));
               }
            }
         }
         for (i = 0; i < 32; i++) {
            if ((1 << i) & type2) {
               list tmp = llGetLinkPrimitiveParams(j+n, [ i, 0 ]); // there's always a side 0
               say(list2safe([ i, ALL_SIDES ] + tmp)); // use it for everything

               for (k = 1; k < llGetLinkNumberOfSides(j+n); k++) {
                  list tmp2 = llGetLinkPrimitiveParams(j+n, [ i, k ]);

                  // only output other sides if they differ from side 0
                  if (!listeq(tmp, tmp2)) {
                     say(list2safe([ i, k ] + tmp2));
                  }
               }
            }
         }
         say(list2safe(["PRIM"]));
      }
      say("");
      llSay(0, "=== END ===");
      llRemoveInventory(llGetScriptName());
   }
}
