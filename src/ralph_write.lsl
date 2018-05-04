// This script is named after "ralph the all purpose animal"
// from the film "twice upon a time"

// use this script to write primitiveparams settings
// thusly creating a new object

#include "safelist.lsl"

integer secret;
string object;
string notecard;

key lines;
integer line;
integer maxline;

string buffer;

void process_buffer() {
   integer i = llSubStringIndex(buffer, "<");
   string s = llGetSubString(buffer, 0, i - 1);
   buffer = llGetSubString(buffer, i, -1);

   if (buffer == "<") {
      buffer = "";
   }
   else {
      buffer = llGetSubString(buffer, 1, -1);
   }

   llSay(secret, s);
   //llOwnerSay(s);
   //llSleep(0.06);
}

default {
   state_entry () {
      secret = (integer) (llFrand(1024.0) + 1024.0);
      object = llGetInventoryName(INVENTORY_OBJECT, 0);
      notecard = llGetInventoryName(INVENTORY_NOTECARD, 0);
      llListen(secret, "", NULL_KEY, "");
   }

   touch_start (integer unused_i) {
      line = 0;
      llRezObject(object, llGetPos() + <0,0,5>, ZERO_VECTOR, ZERO_ROTATION, secret);
   }

   listen (integer channel, string name, key id, string mesg) {
      list l = safe2list(mesg);

      if (llList2String(l, 0) == "PRIMS") {
         line++;
         llGetNotecardLine(notecard, line);
      }
      if (llList2String(l, 0) == "READY") {
         lines = llGetNumberOfNotecardLines(notecard);
      }
   }

   dataserver (key id, string data) {
      if (id == lines) {
         line = 0;
         maxline = (integer) data;
         llGetNotecardLine(notecard, line);
      }
      else {
         buffer = buffer + data;
         while (-1 != llSubStringIndex(buffer, "<")) {
            process_buffer();
         }

         line++;
         if (line < maxline) {
            llGetNotecardLine(notecard, line);
         }
         else {
            llSay(secret, list2safe(["FINI"]));
         }
      }
   }
}
