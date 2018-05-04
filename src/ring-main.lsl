// main.lsl
// main openrings script
//
// Open Stargate Project
// Copyright (C) 2007, 2008, 2009 Adam Wozniak, Doran Zemlja, and CB Radek
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    PLEASE READ THE README FILE
//
////////////////////////////////////////////////////////////////////////////////////////////////

#include "global.h"

integer ringchannel = -3141592;
integer dialogchannel = -3141593;

list others = [];
list rings = [];

key transport_key = NULL_KEY;
key actor = NULL_KEY;

integer allrings = TRUE;
integer ninepass = TRUE;
integer nontemp = TRUE;
integer texture = 1;

key destination;

integer NUM_RINGS = 5; // constant!

// Start ring process
rezRings()
{
   if (llGetListLength(rings)) {
      return;
   }

   // set the ring base texture
   llSetPrimitiveParams([PRIM_GLOW, 0, 1.0]);

   llTriggerSound("ringSound", 1.0);
   // rez the first ring
   llRezObject("ring_" + (string) texture, // object name
         llGetPos() + <0.0,0.0,0.1>,
         ZERO_VECTOR,
         llGetRot(), // llEuler2Rot(<0,0,0>*DEG_TO_RAD),
         NUM_RINGS); // position value sent to new ring object
}

// called when transport is complete.
// lowering ring back down in reverse sequence.
deRezRings()
{
   integer i;
   integer max = llGetListLength(rings);

   for (i = 0; i < max; i++) {
      ringsend(llList2Key(rings, i), "Die");
   }

   rings = [];

   // set the ring base texture
   llSetPrimitiveParams([PRIM_GLOW, 0, 0.0]);
}

onRingRez(key id) {

   // add to FRONT to make derez iteration easy
   rings = [ id ] + rings;

   // when we've identified the key of the ring, we say a quick hello to
   // give the ring our key. Otherwise it wouldn't know future messages were from us
   ringsend(id, "HelloRing");

   if (llGetListLength(rings) == NUM_RINGS) {
      ringsend(transport_key, "commenceTransport");
   }
   else {
      llRezObject("ring_" + (string) texture, // object name
            llGetPos() + <0.0,0.0,0.1>,
            ZERO_VECTOR,
            llEuler2Rot(<0,0,0>*DEG_TO_RAD),
            NUM_RINGS - llGetListLength(rings)); // position value sent to new ring object
   }
}

activate(key id) {
   if (transport_key != NULL_KEY) {
      if ("" == llKey2Name(transport_key)) {
         transport_key = NULL_KEY;
      }
   }

   if (transport_key == NULL_KEY) {
      if (ninepass) {
         llRezObject("TransportPrim-9", llGetPos() + <0.0,0.0,1.5>, <0.0,0.0,0.0>, llGetRot(), 10);
      }
      else {
         llRezObject("TransportPrim-17", llGetPos() + <0.0,0.0,1.5>, <0.0,0.0,0.0>, llGetRot(), 10);
      }
      actor = id;
      ringsend(NULL_KEY,"openDoors");
   }
}

integer set_destination(string name) {
   integer ret = FALSE;
   integer i;
   integer max = llGetListLength(others);
   list l;

   for (i = 0; i < max; i++) {
      l = llGetObjectDetails(llList2Key(others, i), [OBJECT_DESC, OBJECT_OWNER]);
      if (llGetListLength(l)) {
         if ("" == llList2String(l, 0)) {
            l = llListReplaceList(l, [ (string) llList2Key(others, i) ], 0, 0);
         }
         if (allrings || (key)llList2String(l, 1) == llGetOwner()) {
            if (name == llList2String(l, 0)) {
               destination = llList2Key(others, i);
               ret = TRUE;
            }
         }
      }
   }

   return ret;
}

transport() {
   ringsend(transport_key, "ringDest:" + (string) destination);
}

addring(key id) {
   if (-1 == llListFindList(others, [ id ])) {
      others += id;
   }
}

ringsend(key to, string mesg) {
   llRegionSay(ringchannel, llDumpList2String([to, llGetKey(), mesg], ":"));
}

transport_dialog(key id, integer page) {
   integer i;
   integer max = llGetListLength(others);
   list l;
   list names;

   for (i = 0; i < max; i++) {
      l = llGetObjectDetails(llList2Key(others, i), [OBJECT_DESC, OBJECT_OWNER]);
      if (llGetListLength(l)) {
         if ("" == llList2String(l, 0)) {
            l = llListReplaceList(l, [ (string) llList2Key(others, i) ], 0, 0);
         }
         if (allrings || (key) llList2String(l, 1) == llGetOwner()) {
            names += llList2String(l, 0);
         }
      }
   }

   names = llListSort(names, 1, 1);

   if (id == llGetOwner()) {
      names = [ "OPTIONS" ] + names;
   }

   if (llGetListLength(names) > 12) {
      page = page % (1+((llGetListLength(names) - 1) / 11));
      names = llList2List(names, 11*page, 11*page+10);
      names = names + [ ">>> " + (string) (page+1) + " >>>" ];
   }

   llDialog(id, "Choose your destination", names, dialogchannel);
}

recv(string mesg) {
   list l = llParseString2List(mesg, [ ":" ], []);
   string to = llList2String(l, 0);
   string from = llList2String(l, 1);
   mesg = llList2String(l, 2);

   if ((key) to == llGetKey() || to == "*") {
      if (mesg == "beacon") {
         addring(from);
      }
      else if (mesg == "ringPing") {
         addring(from);
         ringsend(from, "ringPong");
      }
      else if (mesg == "ringPong") {
         addring(from);
      }
      else if (mesg == "rezRings") {
         rezRings();
         particles_on();
      }
      else if (mesg == "incomingTransport") {
         rezRings();
         particles_on();
         llSay(0, "Incoming transport...");
      }
      else if (mesg == "deRezRings" || mesg == "transportPrimDead") {
         deRezRings();
         particles_off();
      }
      else if (mesg == "remoteActivate") {
         activate(llGetOwnerKey(from));
      }
   }
}

beacon() {
   ringsend("*", "beacon");
}

ringPing() {
   ringsend("*", "ringPing");
}

do_transportabort(key id) {
   llDialog(id, "Awaiting command.", ["Transport", "<----->", "Abort"], dialogchannel);
}

do_texture(key id) {
   list options;
   integer i;
   integer max = llGetInventoryNumber(INVENTORY_OBJECT);

   for (i = 0; i < max; i++) {
      if (NULL_KEY != llGetInventoryKey("ring_" + (string) i)) {
         options += (string) i;
      }
   }

   llDialog(id, "Textures\nChoose your favorite:", options, dialogchannel);
}

do_options(key id) {
   list options;

   if (allrings) {
      options += "Own Rings";
   }
   else {
      options += "All Rings";
   }

   if (ninepass) {
      options += "17 Pass";
   }
   else {
      options += "9 Pass";
   }

   options += "Texture";

   options += "RESET";

   if (nontemp) {
      options += "Temp Rez";
   }
   else {
      options += "Non-Temp";
   }

   options = [ "BACK" ] + options;

   llDialog(id, "Options Menu", options, dialogchannel);
}

particles_off() {
   llParticleSystem([
         PSYS_PART_FLAGS , PSYS_PART_EMISSIVE_MASK,
         PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY,
         PSYS_SRC_TEXTURE,           "2d1cc751-383e-910a-dc3c-c8793bacf90c",
         PSYS_SRC_MAX_AGE,           2.0,
         PSYS_PART_MAX_AGE,          1.0,
         PSYS_SRC_BURST_RATE,        0.02,
         PSYS_SRC_BURST_PART_COUNT,  8,
         PSYS_SRC_BURST_RADIUS,      6.0,
         PSYS_SRC_BURST_SPEED_MIN,   19.5,
         PSYS_SRC_BURST_SPEED_MAX,   20.0,
         PSYS_SRC_ACCEL,             <0.0,0.0,4.0>,
         PSYS_PART_START_COLOR,      <1.0,1.0,1.0>,
         PSYS_PART_START_ALPHA,      0.0,
         PSYS_PART_END_ALPHA,        0.0,
         PSYS_PART_START_SCALE,      <6.0,6.0,0.0>,
         PSYS_SRC_ANGLE_BEGIN,       PI,
         PSYS_SRC_ANGLE_END,         PI,
         PSYS_SRC_OMEGA,             <0.0,0.0,0.0>
         ]);
}

particles_on() {
   llParticleSystem([
         PSYS_PART_FLAGS , PSYS_PART_EMISSIVE_MASK,
         PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY,
         PSYS_SRC_TEXTURE,           "2d1cc751-383e-910a-dc3c-c8793bacf90c",
         PSYS_SRC_MAX_AGE,           2.0,
         PSYS_PART_MAX_AGE,          1.0,
         PSYS_SRC_BURST_RATE,        0.02,
         PSYS_SRC_BURST_PART_COUNT,  8,
         PSYS_SRC_BURST_RADIUS,      6.0,
         PSYS_SRC_BURST_SPEED_MIN,   19.5,
         PSYS_SRC_BURST_SPEED_MAX,   20.0,
         PSYS_SRC_ACCEL,             <0.0,0.0,4.0>,
         PSYS_PART_START_COLOR,      <1.0,1.0,1.0>,
         PSYS_PART_START_ALPHA,      1.0,
         PSYS_PART_END_ALPHA,        1.0,
         PSYS_PART_START_SCALE,      <6.0,6.0,0.0>,
         PSYS_SRC_ANGLE_BEGIN,       PI,
         PSYS_SRC_ANGLE_END,         PI,
         PSYS_SRC_OMEGA,             <0.0,0.0,0.0>
         ]);
}

default {
   state_entry() {

      llSetTexture(llGetInventoryKey("}top_" + (string) texture), 0);
      llSetTexture(llGetInventoryKey("}outer_" + (string) texture), 1);
      llSetTexture(llGetInventoryKey("}inner_" + (string) texture), 2);
      llSetTexture(llGetInventoryKey("}bottom_" + (string) texture), 3);

      particles_off();
      dialogchannel += (integer) llFrand(4096);
      llListen(ringchannel, "", NULL_KEY, "");
      llListen(dialogchannel, "", NULL_KEY, "");
      llSetTimerEvent(60.0);
      beacon();
      ringPing();
   }

   on_rez(integer unused_param) {
      llSetObjectDesc(llGetSubString((string)llGetKey(), 0, 7));
      llResetScript();
   }

   listen(integer channel, string unused_name, key id, string mesg) {
      //llSay(0, llDumpList2String([channel,name,id,mesg], "   "));
      if (channel == ringchannel) {
         recv(mesg);
      }
      else if (channel == dialogchannel) {
         if (0 == llSubStringIndex(mesg, ">>> ")) {
            transport_dialog(id, (integer) llGetSubString(mesg, 4, -1));
         }
         else if (mesg == "OPTIONS") {
            do_options(id);
         }
         else if (mesg == "BACK") {
            transport_dialog(id, 0);
         }
         else if (mesg == "Own Rings") {
            allrings = FALSE;
            do_options(id);
         }
         else if (mesg == "All Rings") {
            allrings = TRUE;
            do_options(id);
         }
         else if (mesg == "9 Pass") {
            ninepass = TRUE;
            do_options(id);
         }
         else if (mesg == "17 Pass") {
            ninepass = FALSE;
            do_options(id);
         }
         else if (mesg == "Temp Rez") {
            nontemp = FALSE;
            do_options(id);
         }
         else if (mesg == "Non-Temp") {
            nontemp = TRUE;
            do_options(id);
         }
         else if (mesg == "Texture") {
            do_texture(id);
         }
         else if (mesg == "RESET") {
            llResetScript();
         }
         else if (llGetInventoryKey("ring_"+mesg) != NULL_KEY) {
            texture = (integer) mesg;
            llSetTexture(llGetInventoryKey("}top_" + (string) texture), 0);
            llSetTexture(llGetInventoryKey("}outer_" + (string) texture), 1);
            llSetTexture(llGetInventoryKey("}inner_" + (string) texture), 2);
            llSetTexture(llGetInventoryKey("}bottom_" + (string) texture), 3);
         }
         else if (mesg == "<----->") {
            do_transportabort(id);
         }
         else if (mesg == "Abort") {
            ringsend(transport_key, "abortTransport");
         }
         else if (mesg == "Transport") {
            transport();
         }
         else if (set_destination(mesg)){
            do_transportabort(id);
         }
      }
      else {
      }
   }

   touch_start(integer unused_count) {
      activate(llDetectedKey(0));
   }

   object_rez(key id) {
      string s = llKey2Name(id);

      if (0 == llSubStringIndex(s, "TransportPrim")) {
         transport_key = id;

         llGiveInventory(transport_key, "Smoke");
         llGiveInventory(transport_key, "Transparent");
         llRemoteLoadScriptPin(id, "}ring-prim.o", 3141592, 1, ringchannel);

         transport_dialog(actor, 0);
      }
      else if (0 == llSubStringIndex(s, "ring")) {
         onRingRez(id);
      }
   }

   timer(){
      beacon();
   }
}
