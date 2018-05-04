// package

#include "global.h"
#include "invfix.lsl"
#include "objname.lsl"
#include "int2hex.lsl"

#define DEBUG_ENABLED hasflag("debug:pkg")
#define llIfDebugSay(x) if (DEBUG_ENABLED) { llDebugSay(x); }

#define ROLE_DELIVERY 0
#define ROLE_PACKAGE 1
#define ROLE_OBJECT 2

float textAlpha = 1.0;
integer upcount = 0;
integer last_renew = 0;
integer last_announce = 0;

integer world_channel = 0x0114A945;
integer my_channel = 0;
integer my_role;
integer countdown = 0;
integer handle = 0;
integer worldhandle = 0;
integer lastchange;
integer particle_system_count_down = 0;
integer removing_count_down = 0;
integer need_resets = 1;

key original_key;
string original_name;

// one list per state...
list state_unknown;
list state_ready_remove;
list state_removing;
list state_ready_add;
list state_adding;
list state_ok;

list deliverers;
list renewed;

#ifdef USE_INERT
integer inert = 0;
#endif

list status_text_list;

void myRezObject(string name, vector pos, vector vel, rotation rot, integer channel) {
   llIfDebugSay("attempting to rez " + name);
   llRezObject(name, pos, vel, rot, channel);
}
#define llRezObject(n,p,v,r,c) myRezObject(n,p,v,r,c);

void status_text(key id, string s) {
   llSayAll(channelof(id), "STATUS " + s);
}

void add_status_text(string name, string msg) {
   status_text_list += [ name + ":" + llGetSubString(msg, 7, -1), llGetUnixTime() + 6];
}

void status_text_timer() {
   if (!llGetListLength(status_text_list)) {
      return;
   }

   while (llGetListLength(status_text_list) &&
         llGetUnixTime() > (integer) llList2String(status_text_list, 1)) {
      status_text_list = llDeleteSubList(status_text_list, 0, 1);
   }

   if (llGetListLength(status_text_list)) {
      llSetText(
            llDumpList2String(llList2ListStrided(status_text_list, 0, -1, 2), "\n"),
            <1.0,1.0,0.0>, 1.0);
   }
   else {
      llSetText("", <1.0,1.0,0.0>, 0.0);
   }
}

void announce() {
   llSayAll(world_channel, "PKG " + int2hex(DATE) + " " + int2hex(TIME));

   if (my_role == ROLE_DELIVERY) {
      llSayAll(world_channel, "DELIVERY " + int2hex(DATE) + " " + int2hex(TIME));
      llSayAll(world_channel, "CHANGED");
   }

   last_announce = llGetUnixTime();
}

void initialize() {
   if (handle != 0) {
      llListenRemove(handle);
   }

   if (worldhandle != 0) {
      llListenRemove(worldhandle);
   }

   last_renew = 0;

   llParticleSystem([]);

   original_name = llGetScriptName();
   original_key = llGetInventoryKey(original_name);

   my_channel = channelof(llGetKey());
   llSetRemoteScriptAccessPin(my_channel);
   my_role = role();
   worldhandle = llListen(world_channel, "", NULL_KEY, "");
   handle = llListen(my_channel, "", NULL_KEY, "");

   llIfDebugSay((string)my_role + " " + (string) worldhandle + " " + (string) handle);

   announce();

   llSetTimerEvent(1);
}

void point_at(key id) {
   llParticleSystem([
         PSYS_PART_FLAGS, PSYS_PART_TARGET_POS_MASK |
         PSYS_PART_TARGET_LINEAR_MASK | PSYS_PART_EMISSIVE_MASK,
         PSYS_SRC_TARGET_KEY, id,
         PSYS_PART_MAX_AGE, 2.0,
         PSYS_SRC_BURST_RATE, .2,
         PSYS_SRC_BURST_PART_COUNT, 1
         ]);
   particle_system_count_down = 5;
}

void downcount(integer param) {
   upcount--;
   if (upcount <= 0) {

      // signal that we're done adding
      llSayAll(param, "READY");

      // we don't die; someone may want to RENEW
      // instead we just turn invisible, and wait for TEMP_ON_REZ to time us out

      announce();

      llSetAlpha(0.0, ALL_SIDES);
      llSetText("", ZERO_VECTOR, 0.0);
      textAlpha = 0.0;
      llSetPrimitiveParams([ PRIM_TEMP_ON_REZ, TRUE ]);
   }
}

void llSayAll(integer c, string s) {
   llRegionSay(c, s);
   llIfDebugSay("/" + (string)c + " " + s);
}

integer channelof(key id) {
   return (
      (((integer)("0x" + llGetSubString((string)id,0,7))) & 0x7FFFFFFF) |
      0x40000000);
}

integer role() {
   list inventory_all = llGetInventoryList(INVENTORY_ALL);
   integer max = llGetListLength(inventory_all);
   integer i;
   string s;

   if (llGetInventoryNumber(INVENTORY_CLOTHING)) {
      // we're a delivery boy, full of packages
      return ROLE_DELIVERY;
   }

   for (i = 0; i < max; i++) {
      s = llList2String(inventory_all, i);
      if (llGetScriptName() != s) {
         if (llSubStringIndex(s, "~pkg~") == 0) {
            // we want packages
            return ROLE_OBJECT;
         }
      }
   }

   // we're a package, no packages inside
   llSetText(llGetObjectName(), <1,1,1>, textAlpha);
   return ROLE_PACKAGE;
}

void clean_inventory() {
   integer max;
   integer i;
   list l = [];
   string name;
   list inventory_all = llGetInventoryList(INVENTORY_ALL);

   max = llGetListLength(inventory_all);
   for (i = 0; i < max; i++) {
      name = llList2String(inventory_all, i);
      if (-1 != llSubStringIndex(name, " ")) {
         l = l + [ name ];
      }
   }

   max = llGetListLength(l);
   for (i = 0; i < max; i++) {
      if (llGetInventoryType(llList2String(l,i)) == INVENTORY_SCRIPT) {
         llSetScriptState(llList2String(l,i), 0);
      }
      llRemoveInventory(llList2String(l, i));
   }
}

integer ispackage(string s) {
   integer ret = (0 == llSubStringIndex(s, "~pkg~"));
   return ret;
}

string pkgname(string s) {
   return llList2String(llParseString2List(s, ["~"], []), 1);
}

string pkgnum(string s) {
   return llList2String(llParseString2List(s, ["~"], []), 2);
}

integer contains(string name) {
   return (NULL_KEY != llGetInventoryKey(name));
}

list purge(list in) {
   list out;

   integer max = llGetListLength(in);
   integer i;

   string name;

   for (i = 0; i < max; i++) {
      name = llList2String(in, i);
      if (contains(name)) {
         out = out + name;
      }
   }

   return out;
}

void find_new() {
   integer max;
   integer i;
   string name;
   list inventory_object = llGetInventoryList(INVENTORY_OBJECT);

   max = llGetListLength(inventory_object);
   for (i = 0; i < max; i++) {
      name = llList2String(inventory_object, i);
      if (ispackage(name)) {
         if (pkgname(name) == "pkg") {
            if (INVENTORY_NONE == llGetInventoryType(name)) {
               llIfDebugSay("error: " + name + " is type NONE, resetting to recover");
               // aw hell...
               llResetScript();
            }
            llRezObject(name, llGetPos(),
               ZERO_VECTOR, ZERO_ROTATION, my_channel);
            llRemoveInventory(name);
            llIfDebugSay("rezzed pkg update " + name);
         }
         else if (
               -1 == llListFindList(state_adding, [ name ]) &&
               -1 == llListFindList(state_removing, [ name ]) &&
               -1 == llListFindList(state_ready_add, [ name ]) &&
               -1 == llListFindList(state_ready_remove, [ name ]) &&
               -1 == llListFindList(state_ok, [ name ]) &&
               -1 == llListFindList(state_unknown, [ name ])
            ) {
            llIfDebugSay("adding " + name + " to state_unknown");
            state_unknown += name;
         }
         else {
            string stat = "";
            if (DEBUG_ENABLED) {
               if (-1 != llListFindList(state_adding, [ name ])) {
                  stat += ":state_adding";
               }
               if (-1 != llListFindList(state_removing, [ name ])) {
                  stat += ":state_removing";
               }
               if (-1 != llListFindList(state_ready_add, [ name ])) {
                  stat += ":state_ready_add";
               }
               if (-1 != llListFindList(state_ready_remove, [ name ])) {
                  stat += ":state_ready_remove";
               }
               if (-1 != llListFindList(state_ok, [ name ])) {
                  stat += ":state_ready_ok";
               }
               if (-1 != llListFindList(state_unknown, [ name ])) {
                  stat += ":state_unknown";
               }
               llDebugSay("package " + name + " in" + stat);
            }
         }
      }
      else {
         llIfDebugSay("object " + name + " is not a package");
      }
   }
}

void purge_gone() {
   state_ready_remove = purge(state_ready_remove);
   state_unknown = purge(state_unknown);
   state_ok = purge(state_ok);
   state_ready_add = purge(state_ready_add);
   state_adding = purge(state_adding);
   state_removing = purge(state_removing);
}

list remove_entry(list in, string name) {
   integer i = llListFindList(in, [ name ]);
   if (i != -1) {
      return llDeleteSubList(in, i, i);
   }
   else {
      return in;
   }
}

list find_later(string name, list state_) {
   integer max = llGetListLength(state_);
   integer i;

   string pkgname = pkgname(name);
   integer pkgrev = (integer) pkgnum(name);

   string oname;
   integer orev;

   list ret = [];

   for (i = 0; i < max; i++) {
      oname = llList2String(state_, i);
      if (pkgname == pkgname(oname)) {
         orev = (integer) pkgnum(oname);

         if (pkgrev < orev) {
            ret += oname;
         }
      }
   }
   return ret;
}

list find_earlier(string name, list state_) {
   integer max = llGetListLength(state_);
   integer i;

   string pkgname = pkgname(name);
   integer pkgrev = (integer) pkgnum(name);

   string oname;
   integer orev;

   list ret = [];

   for (i = 0; i < max; i++) {
      oname = llList2String(state_, i);
      if (pkgname == pkgname(oname)) {
         orev = (integer) pkgnum(oname);

         if (pkgrev > orev) {
            ret += oname;
         }
      }
   }
   return ret;
}

void sort_unknown() {
   integer max = llGetListLength(state_unknown);
   integer i;
   integer j;
   list l;
   integer jmax;
   string name;

   // don't do ANYTHING with unknowns until all state_adding and state_removing are clear
   if (llGetListLength(state_adding) || llGetListLength(state_removing)) {
      return;
   }

   for (i = 0; i < max; i++) {
      name = llList2String(state_unknown, i);

      // if anything in state_ready_add is earlier than us, remove it
      l = find_earlier(name, state_ready_add);
      jmax = llGetListLength(l);
      for (j = 0; j < jmax; j++) {
         state_ready_add = remove_entry(state_ready_add, llList2String(l, j));
         state_ready_remove += llList2String(l, j);
      }
      if (jmax) {
         state_ready_add += llList2String(l, j);
      }

      // if anything in state_ok is earlier than us, remove it
      l = find_earlier(name, state_ok);
      jmax = llGetListLength(l);
      for (j = 0; j < jmax; j++) {
         state_ok = remove_entry(state_ok, llList2String(l, j));
         state_ready_remove += llList2String(l, j);
      }
      if (jmax) {
         state_ready_add += llList2String(l, j);
      }

      // if anything in state_ok is later than us, remove us
      if (llGetListLength(find_later(name, state_ok))) {
         state_ready_remove += name;
      }
      else if (llGetListLength(find_later(name, state_ready_add))) {
         state_ready_remove += name;
      }
      else {
         state_ready_add += name;
      }
   }
   state_unknown = [];
}

void maybe_rez() {
   if (llGetListLength(state_ready_remove)) {
      need_resets = 1;
      while (llGetListLength(state_ready_remove)) {
         if (INVENTORY_NONE == llGetInventoryType(llList2String(state_ready_remove, 0))) {
            // aw hell...
            llResetScript();
         }
         llRezObject(llList2String(state_ready_remove, 0), llGetPos(),
            ZERO_VECTOR, ZERO_ROTATION, -my_channel);
         state_removing += llList2String(state_ready_remove, 0);
         state_ready_remove = llDeleteSubList(state_ready_remove, 0, 0);
         removing_count_down = 90;
      }
   }
}

void handle_anything() {
   clean_inventory();
   find_new();
   purge_gone();
   sort_unknown();
   maybe_rez();
}

default {
   state_entry() {
      llIfDebugSay("::state_entry");

      initialize();

      if (my_role != ROLE_DELIVERY) {
         handle_anything();
      }
   }

   touch_start(integer unused_n) {
      llIfDebugSay("::touch_start(" + (string) unused_n + ")");
      if (DEBUG_ENABLED) {
         integer max;
         integer i;
         string s;
         list inventory_script = llGetInventoryList(INVENTORY_SCRIPT);
         max = llGetListLength(inventory_script);
         for (i = 0; i < max; i++) {
            s = llList2String(inventory_script, i);
            if (llGetScriptState(s)) {
               s = s + ":ok";
            }
            else {
               s = s + ":FAIL";
            }
            llDebugSay("script " + s);
         }

         llDebugSay("state_unknown:" + llDumpList2String(state_unknown, ","));
         llDebugSay("state_ready_add:" + llDumpList2String(state_ready_add, ","));
         llDebugSay("state_adding:" + llDumpList2String(state_adding, ","));
         llDebugSay("state_ready_remove:" + llDumpList2String(state_ready_remove, ","));
         llDebugSay("state_removing:" + llDumpList2String(state_removing, ","));
         llDebugSay("state_ok:" + llDumpList2String(state_ok, ","));
      }
   }

   timer() {
      llIfDebugSay("::timer");
      if (my_role == ROLE_PACKAGE) {
         // we're a package, no packages inside
         llSetText(llGetObjectName(), <1,1,1>, textAlpha);
      }

      if (my_role == ROLE_OBJECT) {
         status_text_timer();
      }

      if (particle_system_count_down) {
         particle_system_count_down--;
         if (!particle_system_count_down) {
            llParticleSystem([]);
         }
      }

      if (removing_count_down) {
         removing_count_down--;
         if (removing_count_down == 0) {
            while (llGetListLength(state_removing)) {
               llIfDebugSay("force remove " + llList2String(state_removing, 0));
               llRemoveInventory(llList2String(state_removing, 0));
               state_removing = llDeleteSubList(state_removing, 0, 0);
            }
         }
      }

#ifdef USE_INERT
      if (inert) {
         return;
      }

      if (original_name != llGetScriptName() || original_key != llGetInventoryKey(llGetScriptName())) {
         // it's the end of the world as we know it...
         llListenRemove(handle);
         llListenRemove(worldhandle);
         llSetTimerEvent(0);
         inert = 1;
         return;
      }
#endif

      if ((llGetUnixTime() - last_announce) > 5) {
         announce();
      }

      if (countdown > 0) {
         countdown--;
         if (!countdown) {
            llAllowInventoryDrop(FALSE);
         }
      }

      if ((llGetUnixTime() - lastchange) > 20) {
         if (!llGetListLength(state_unknown) &&
               !llGetListLength(state_ready_remove) &&
               !llGetListLength(state_removing) &&
               llGetListLength(state_ready_add)) {
            if (INVENTORY_NONE == llGetInventoryType(llList2String(state_ready_add, 0))) {
               // aw hell...
               llResetScript();
            }
            llRezObject(llList2String(state_ready_add, 0), llGetPos(),
                  ZERO_VECTOR, ZERO_ROTATION, my_channel);
            state_adding += llList2String(state_ready_add, 0);
            state_ready_add = llDeleteSubList(state_ready_add, 0, 0);
         }
         else if (my_role != ROLE_DELIVERY) {
            handle_anything();
         }
         lastchange = llGetUnixTime();
      }

      if (need_resets &&
            !llGetListLength(state_unknown) &&
            !llGetListLength(state_ready_remove) &&
            !llGetListLength(state_removing) &&
            !llGetListLength(state_ready_add) &&
            !llGetListLength(state_adding)) {
         integer i;
         integer max;
         list inventory_script = llGetInventoryList(INVENTORY_SCRIPT);
         need_resets = 0;
         max = llGetListLength(inventory_script);
         for (i = 0; i < max; i++) {
            if (llList2String(inventory_script, i) != llGetScriptName()) {
               llResetOtherScript(llList2String(inventory_script, i));
            }
         }
      }
   }

   object_rez(key id) {
      llIfDebugSay("::object_rez(" + (string) id + ")");
      string name = llKey2Name(id);
      llIfDebugSay("successful rez of " + name);
   }

   on_rez(integer param) {
      llIfDebugSay("::on_rez(" + (string) param + ")");

      initialize();

      integer i;
      integer max;
      string s;

      if (param < 0) {
         list inventory_all = llGetInventoryList(INVENTORY_ALL);
         max = llGetListLength(inventory_all);
         for (i = 0; i < max; i++) {
            s = llList2String(inventory_all, i);
            if (s != llGetScriptName()) {
               // tell the target to remove something
               llSayAll(-param, "REMOVE|" + (string) llGetInventoryKey(s) + "|" + s);
            }
         }
         // tell the target we're done
         llSayAll(-param, "FINI");
         llDie();
      }
      else if (param > 0) {
         if (llGetInventoryNumber(INVENTORY_ALL) - llGetInventoryNumber(INVENTORY_SCRIPT)) {
            // signal we have objects to upload
            llSayAll(param, "BULK");
            upcount++;
         }
         list inventory_script = llGetInventoryList(INVENTORY_SCRIPT);
         max = llGetListLength(inventory_script);
         for (i = 0; i < max; i++) {
            s = llList2String(inventory_script, i);
            if (s != llGetScriptName()) {
               // signal we have a script to upload
               llSayAll(param, "ADD|" + (string) llGetInventoryKey(s) + "|" + s);
               upcount++;
            }
         }
         if (upcount <= 0) {
            // nothing to do, spoof an up followed immediately by a down
            upcount++;
            downcount(param);
         }
#if 0
         llSayAll(world_channel, "PKG " + (string) DATE + " " + (string) TIME);
         llSetAlpha(0.0, ALL_SIDES);
         llSetText("", ZERO_VECTOR, 0.0);
         textAlpha = 0.0;
         llSetPrimitiveParams([ PRIM_TEMP_ON_REZ, TRUE ]);
#endif
      }
      else { // param == 0
         llResetScript();
      }
   }

   listen(integer unused_channel, string name, key id, string msg) {
      llIfDebugSay("::listen(" + (string) unused_channel + "," + name + "," + (string) id + "," + msg + ")");

      integer i;
      integer i1;
      integer max;
      list l;
      string s1;
      string s2;
      string s3;
      string s4;
      integer mine;
      integer theirs;

#ifdef USE_INERT
      if (inert) {
         return;
      }
#endif

      if (llSubStringIndex(msg, "STATUS ") == 0 && my_role == ROLE_OBJECT) {
         add_status_text(name, msg);
      }
      if (msg == "CHANGED") {
         i = llListFindList(deliverers, [ id ]);
         if (i != -1) {
            deliverers = llDeleteSubList(deliverers, i, i);
         }
      }
      if (llSubStringIndex(msg, "PKG ") == 0) {
         if (my_role == ROLE_OBJECT) {
            l = llParseString2List(msg, [" "], []);
            if (llGetListLength(l) > 1) {
               if ((integer) llList2String(l,1) > DATE ||
                     ((integer) llList2String(l,1) == DATE &&
                      (integer) llList2String(l,2) > TIME)) {
                  if (llGetOwnerKey(id) == llGetOwner()) {
                     if (llGetUnixTime() - last_renew > 5) {
                        llSayAll(channelof(id), "RENEW");
                        last_renew = llGetUnixTime();
                     }
                  }
               }
            }
         }
      }
      if (llSubStringIndex(msg, "DELIVERY ") == 0) {
         if (my_role == ROLE_OBJECT) {
            if (-1 == llListFindList(deliverers, [ id ])) {
               deliverers = [ id ] + deliverers;
               llSayAll(channelof(id), "WHAT");
               if (llGetListLength(deliverers) > 10) {
                  deliverers = llDeleteSubList(deliverers, -1, -1);
               }
            }
         }
      }
      if (msg == "WHAT") {
         list inventory_object = llGetInventoryList(INVENTORY_OBJECT);
         max = llGetListLength(inventory_object);
         for (i = 0; i < max; i++) {
            llSayAll(channelof(id), "HAVE" + llList2String(inventory_object, i));
         }
      }
      if (0 == llSubStringIndex(msg, "HAVE")) {
         // someone is advertising that they have something

         // HAVE~pkg~foo~123~dep1~dep2

#define s1_pkgname s1
#define s2_theyhave s2
#define s3_ihave s3
#define s4_tmp s4

         l = llParseString2List(msg, ["~"], []);
         s1_pkgname = llList2String(l, 2);
         s2_theyhave = llGetSubString(msg, 4, -1);
         s3_ihave = "";
         theirs = (integer) llList2String(l, 3);
         mine = -1;

         list inventory_object = llGetInventoryList(INVENTORY_OBJECT);
         max = llGetListLength(inventory_object);
         for (i = 0; i < max; i++) {
            s4_tmp = llList2String(inventory_object, i);
            if (0 == llSubStringIndex(s4_tmp, "~pkg~")) {
               l = llParseString2List(s4_tmp, [ "~" ], []);
               i1 = llListFindList(l, [ s1_pkgname ]);
               if (i1 != -1) {
                  if (i1 == 1) {
                     mine = (integer) llList2String(l, 2);
                     s3_ihave = s4_tmp;
                  }
                  else if (mine == -1) {
                     mine = 0;
                  }
               }
            }
         }

         if (mine >= 0 && mine < theirs) {
            // signal that we want it, and allow inventory drops
            llAllowInventoryDrop(TRUE);
            countdown = 120;
            llSayAll(channelof(id), "WANT" + s2_theyhave);
         }
      }
      if (0 == llSubStringIndex(msg, "WANT")) {
         // someone wants something, let's give it to them
         s1 = llGetSubString(msg, 4, -1);
         point_at(id);
         llGiveInventory(id, s1);
      }
      if (msg == "BULK") {
         // someone is offering a bulk upload
         // signal we're ready to accept objects
         llSayAll(channelof(id), "DUMP");
      }
      if (msg == "DUMP") {
         // target is ready to accept; let 'em have it!
         l = [];
         list inventory_all = llGetInventoryList(INVENTORY_ALL);
         max = llGetListLength(inventory_all);
         for (i = 0; i < max; i++) {
            s1 = llList2String(inventory_all, i);
            if (llGetInventoryType(s1) != INVENTORY_SCRIPT) {
               l += s1;
            }
         }
         point_at(id);
         status_text(id, "DUMP");
         llGiveInventoryList(id, "null", l);
         downcount(llGetStartParameter());
      }
      if (0 == llSubStringIndex(msg, "REMOVE|")) {
         // they want us to remove something
         l = llParseString2List(msg, ["|"], []);
         s1 = llList2String(l, 1);
         s2 = llList2String(l, 2);
         if (NULL_KEY != llGetInventoryKey(s2)) {
            if ((key) s1 != llGetInventoryKey(s2)) {
               llDebugSay("WARNING: expected key " + (string) s1 +
                  " for '" + s2 + "' but found key " + (string) llGetInventoryKey(s2));
            }
            if (llGetInventoryType(s2) == INVENTORY_SCRIPT) {
               llSetScriptState(s2, 0);
            }
            llRemoveInventory(s2);
         }
      }
      if (0 == llSubStringIndex(msg, "ADD|")) {
         // they have a script, tell them we can take it
         l = llParseString2List(msg, ["|"], []);
         s1 = llList2String(l, 1);
         s2 = llList2String(l, 2);
         llSayAll(channelof(id), "TAKE|" + s2);
      }
      if (msg == "RENEW") {
         if (llGetOwnerKey(id) == llGetOwner() && llListFindList(renewed, [ id ]) == -1) {
            point_at(id);
            llRemoteLoadScriptPin(id, llGetScriptName(), channelof(id), 1, 0);
            renewed = [ id ] + renewed;
         }
      }
      if (0 == llSubStringIndex(msg, "TAKE|")) {
         // we have a script, and target wants to take it
         l = llParseString2List(msg, ["|"], []);
         s1 = llList2String(l, 1);
         point_at(id);
         status_text(id, "ADD " + s1);
         if (llGetInventoryType(s1) == INVENTORY_SCRIPT) {
            llRemoteLoadScriptPin(id, s1, channelof(id), 1, 0);
         }
         else {
            llGiveInventory(id, s1);
         }
         downcount(llGetStartParameter());
      }
      if (msg == "FINI") {
         // someone is done removing stuff from us
         i = llListFindList(state_removing, [ name ]);
         if (i != -1) {
            state_removing = llDeleteSubList(state_removing, i, i);
            llRemoveInventory(name);
         }
         if (llGetListLength(state_ready_add)) {
            while (llGetListLength(state_ready_add)) {
               need_resets = 1;
               if (INVENTORY_NONE == llGetInventoryType(llList2String(state_ready_add, 0))) {
                  // aw hell...
                  llResetScript();
               }
               llRezObject(llList2String(state_ready_add, 0), llGetPos(),
                     ZERO_VECTOR, ZERO_ROTATION, my_channel);
               state_adding += llList2String(state_ready_add, 0);
               state_ready_add = llDeleteSubList(state_ready_add, 0, 0);
            }
         }
      }
      if (msg == "READY") { // a ROLE_PACKAGE has completed adding to us
         i = llListFindList(state_adding, [ name ]);
         if (i != -1) {
            state_adding = llDeleteSubList(state_adding, i, i);
            state_ok += name;
         }
      }
   }

   changed(integer change) {
      llIfDebugSay("::changed(" + (string) change + ")");

#ifdef USE_INERT
      if (inert) {
         return;
      }
#endif

      if (change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
         lastchange = llGetUnixTime();

         llIfDebugSay("inventory " + (string) my_role);

         if (my_role == ROLE_DELIVERY) {
            llSayAll(world_channel, "CHANGED");
            return;
         }

         handle_anything();
      }
   }
}
