// This script is named after "ralph the all purpose animal"
// from the film "twice upon a time"

// create two objects,
// put one inside the other,
// put a copy of this script in the parent.

#include "safelist.lsl"

integer target_prims;
integer secret;
string object;

void renumber() {
   if (target_prims > llGetNumberOfPrims()) {
      integer delta = llGetNumberOfPrims() - target_prims - 1;
      integer shift;
      string objectN = object;

      for (shift = 7; shift > 0; shift--) {
         if (delta & (1 << shift)) {
            if (llGetInventoryKey(object + (string) (1 << shift)) != NULL_KEY) {
               objectN = object + (string) (1 << shift);
            }
         }
      }
      
      llOwnerSay("rez="+objectN);
      llRezObject(objectN, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 0);
   }
   else if (target_prims < llGetNumberOfPrims()) {
      llOwnerSay("break="+(string)(llGetNumberOfPrims()-target_prims));
      while (llGetNumberOfPrims() != target_prims) {
         llSetLinkPrimitiveParamsFast(llGetNumberOfPrims(),
               [
               PRIM_TEMP_ON_REZ, TRUE,
               PRIM_SIZE, <.01,.01,.01>,
               PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0.0
               ]);
         llBreakLink(llGetNumberOfPrims());
      }
      llOwnerSay("broken");
      llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
      llSay(secret, list2safe(["PRIMS"]));
   }
   else {
      llOwnerSay("prims="+(string)llGetNumberOfPrims());
      llSay(secret, list2safe(["PRIMS"]));
   }
}

integer primnum = 1;

default {
   state_entry () {
   }

   run_time_permissions (integer unused_perm) {
      llSay(secret, list2safe(["READY"]));
   }

   object_rez (key id) {
      llCreateLink(id, TRUE);
      renumber();
   }

   on_rez (integer param) {
      llOwnerSay("rez, param="+(string) param);

      if (param != 0) {
         llListen(param, "", NULL_KEY, "");
         llSetRemoteScriptAccessPin(param);
         llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
         llAllowInventoryDrop(TRUE);
         secret = param;
         object = llGetInventoryName(INVENTORY_OBJECT, 0);
      }
   }

   listen (integer chan, string name, key id, string mesg) {
      list l = safe2list(mesg);

      if (llList2String(l, 0) == "#") {
         // ignore comments from the peanut gallery
      }
      else if (llList2String(l, 0) == "FINI") {
         integer shift;

         llRemoveInventory(object);

         for (shift = 7; shift > 0; shift--) {
            if (llGetInventoryKey(object + (string) (1 << shift)) != NULL_KEY) {
               llRemoveInventory( object + (string) (1 << shift));
            }
         }

         // TODO FIX: do we also need this? // llSetScriptState(llGetScriptName(), FALSE);
         llRemoveInventory(llGetScriptName());
      }
      else if (llList2String(l, 0) == "PRIMS") {
         target_prims = llList2Integer(l, 1);
         renumber();
      }
      else if (llList2String(l, 0) == "PRIM") {
         primnum++;
      }
      else {
         llSetLinkPrimitiveParamsFast(primnum, l);
      }
   }
}
