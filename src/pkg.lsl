// package

#undef DEBUG

#include "global.h"
#include "invfix.lsl"
#include "objname.lsl"

#define xstr(s) str(s)
#define str(s) #s

#include "ht.lsl"

#ifdef DEBUG
#define DEBUG_ENABLED hasflag("debug:pkg")
#define llIfDebugSay(x) if (DEBUG_ENABLED) { llDebugSay(x); }
#else
#define llIfDebugSay(x)
#endif

#define ROLE_DELIVERY 0
#define ROLE_PACKAGE 1
#define ROLE_OBJECT 2

#define OK_STRING "ok"
#define UNKNOWN_STRING "uk"
#define READY_REMOVE_STRING "rtg"
#define REMOVING_STRING "rem"
#define READY_ADD_STRING "htt"
#define ADDING_STRING "add"

float textAlpha = 1.0;
integer upcount = 0;
integer last_renew = 0;
integer last_announce = 0;

integer world_channel = 0x0114A945; // 18131269
integer my_channel = 0;
integer my_role;
integer countdown = 0;
integer handle = 0;
integer worldhandle = 0;
integer lastchange;
integer particle_system_count_down = 0;
integer removing_count_down = 0;
integer adding_count_down = 0;
integer need_resets = 1;

key original_key;
string original_name;

// a hash table for states
HT_DECLARE(states)

//list state_unknown;
//list state_ready_remove;
//list state_removing;
//list state_ready_add;
//list state_adding;
//list state_ok;

list deliverers;
list renewed;

#ifdef USE_INERT
integer inert = 0;
#endif

list status_text_list;

#ifdef DEBUG
void myRezObject(string name, vector pos, vector vel, rotation rot, integer channel) {
   llIfDebugSay("attempting to rez " + name);
   llRezObject(name, pos, vel, rot, channel);
}
#define llRezObject(n,p,v,r,c) myRezObject(n,p,v,r,c);
#endif

list list_of_ret;

integer list_of_helper(string k, string v, string d) {
   if (v == d) {
      list_of_ret = list_of_ret + k;
   }
   return 0;
}

list list_of(string v) {
   list_of_ret = [];
   HT_ITERATE(states, list_of_helper, v);
   return list_of_ret;
}

#define status_text(id, s) llSayAll(channelof(id), "STATUS " + s);

#define add_status_text(name, msg) status_text_list += [ name + ":" + llGetSubString(msg, 7, -1), llGetUnixTime() + 6]

string statii_txt;
integer statii(string k, string v, integer unused_i) {
   statii_txt = statii_txt + k + " : " + v + "\n";
   return 0;
}

string lasttext = "";

void status_text_timer() {
   string output_lines = "";

   if (!count_of([UNKNOWN_STRING, READY_REMOVE_STRING, REMOVING_STRING, READY_ADD_STRING, ADDING_STRING]) && !llGetListLength(status_text_list)) {
      if (lasttext != "") {
         llSetText("", <1.0,1.0,0.0>, 0.0);
         lasttext = "";
      }
      return;
   }

   while (llGetListLength(status_text_list) &&
         llGetUnixTime() > (integer) llList2String(status_text_list, 1)) {
      status_text_list = llDeleteSubList(status_text_list, 0, 1);
   }

   if (llGetListLength(status_text_list)) {
      output_lines = llDumpList2String(llList2ListStrided(status_text_list, 0, -1, 2), "\n");
   }

   statii_txt = "";
   HT_ITERATE(states, statii, 0);

   llSetText(statii_txt + "=========\n" + output_lines, <1.0,1.0,0.0>, 1.0);
   lasttext = statii_txt;
}

void announce() {
   llSayAll(world_channel, "PKG " + xstr(DATE) + " " + xstr(TIME));

   if (my_role == ROLE_DELIVERY) {
      llSayAll(world_channel, "DELIVERY " + xstr(DATE) + " " + xstr(TIME));
      llSayAll(world_channel, "CHANGED");
   }

   last_announce = llGetUnixTime();
}

void initialize() {
   llIfDebugSay("::initialize");

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
   list inventory_object = llGetInventoryList(INVENTORY_OBJECT);
   integer max = llGetListLength(inventory_object);
   integer i;
   string s;

   if (llGetInventoryNumber(INVENTORY_CLOTHING)) {
      // we're a delivery boy, full of packages
      return ROLE_DELIVERY;
   }

   for (i = 0; i < max; i++) {
      s = llList2String(inventory_object, i);
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
   integer done = 0;
   integer i;
   string s;

   while (!done) {
      done = 1;
      for (i = 0; i < llGetInventoryNumber(INVENTORY_ALL); i++) {
#undef llGetInventoryName
         s = llGetInventoryName(INVENTORY_ALL, i);
#define llGetInventoryName UNSAFE_llGetInventoryName_ERROR
         if (s == "") {
            done = 0;
         }
         else if (-1 != llSubStringIndex(s, " ")) {
            if (llGetInventoryType(s) == INVENTORY_SCRIPT) {
               llSetScriptState(s, 0);
            }
            llRemoveInventory(s);
            done = 0;
         }
      }
   }
}

#define ispackage(s) (0 == llSubStringIndex(s, "~pkg~"))

#define pkgname(s) llList2String(llParseString2List(s, ["~"], []), 1)

#define pkgnum(s) llList2String(llParseString2List(s, ["~"], []), 2)

void find_new() {
   llIfDebugSay(":: find_new " + (string) __LINE__);

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
         else if (! HT_HASKEY(states, name)) {
            llIfDebugSay("adding " + name + " to state_unknown");
            HT_SET(states, name, UNKNOWN_STRING);
         }
         else {
               llIfDebugSay("package " + name + " in " + HT_GET(states, name));
         }
      }
      else {
         llIfDebugSay("object " + name + " is not a package");
      }
   }
}

#define contains(x) (NULL_KEY != llGetInventoryKey(x))

integer purge(string k, string unused_v, string unused_d) {
   llIfDebugSay(":: purge " + (string) __LINE__);
   if (!contains(k)) {
      HT_DELETE(states, k);
   }
   return 0;
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

integer count_of_ret;

integer count_of_helper(string unused_k, string v, list l) {
   if (-1 != llListFindList(l, [ v ])) {
      count_of_ret++;
   }
   return 0;
}

integer count_of(list l) {
   count_of_ret = 0;
   HT_ITERATE(states, count_of_helper, l);
   return count_of_ret;
}

integer sort_unknown_helper(string name, string v, string unused_d) {
   list l;
   integer j;
   integer jmax;

   if (v == UNKNOWN_STRING) {
      // if anything in state_ready_add or state_ok is earlier than us, remove it
      l = find_earlier(name, list_of(READY_ADD_STRING) + list_of(OK_STRING));
      jmax = llGetListLength(l);
      for (j = 0; j < jmax; j++) {
         HT_SET(states, llList2String(l, j), READY_REMOVE_STRING);
      }

      // if anything in state_ok or state_ready_add is later than us, remove us
      // otherwise set us to state_ready_add
      if (llGetListLength(find_later(name, list_of(OK_STRING) + list_of(READY_ADD_STRING)))) {
         HT_SET(states, name, READY_REMOVE_STRING);
      }
      else {
         HT_SET(states, name, READY_ADD_STRING);
      }
   }

   return 0;
}

void sort_unknown() {
   llIfDebugSay(":: sort_unknown " + (string) __LINE__);

   // don't do ANYTHING with unknowns until all state_adding and state_removing are clear
   if (count_of([ADDING_STRING, REMOVING_STRING])) {
      return;
   }

   HT_ITERATE(states, sort_unknown_helper, "");
}

integer maybe_rez(string name, string v, string unused_d) {
   llIfDebugSay(":: maybe_rez " + (string) __LINE__);
   if (v == READY_REMOVE_STRING) {
      need_resets = 1;

      if (INVENTORY_NONE == llGetInventoryType(name)) {
         // aw hell...
         llResetScript();
      }

      llRezObject(name, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, -my_channel);
      HT_SET(states, name, REMOVING_STRING);
      removing_count_down = 90;
   }
   return 0;
}

void handle_anything() {
   llIfDebugSay("::initialize");
   clean_inventory();
   find_new();
   HT_ITERATE(states, purge, "");
   sort_unknown();
   HT_ITERATE(states, maybe_rez, "");
}

integer do_adds(string k, string v, string unused_d) {
   if (v == READY_ADD_STRING) {
      need_resets = 1;
      if (INVENTORY_NONE == llGetInventoryType(k)) {
         // aw hell...
         llResetScript();
      }
      llRezObject(k, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, my_channel);
      HT_SET(states, k, ADDING_STRING);
      adding_count_down = 90;
   }
   return 0;
}

#ifdef DEBUG
integer dump_states(string k, string v, string unused_d) {
   llDebugSay(k + ":" + v);
   return 0;
}
#endif

integer force_remove(string k, string v, integer unused_d) {
   if (v == REMOVING_STRING) {
      llIfDebugSay("force remove " + k);
      llRemoveInventory(k);
      HT_DELETE(states, k);
   }
   return 0;
}

integer force_readd(string k, string v, integer unused_d) {
   if (v == ADDING_STRING) {
      llIfDebugSay("force readd " + k);
      HT_SET(states, k, READY_ADD_STRING);
   }
   return 0;
}

void target_remove(integer param) {
   string s;
   list inventory_all = llGetInventoryList(INVENTORY_ALL);
   integer max = llGetListLength(inventory_all);
   integer i;
   for (i = 0; i < max; i++) {
      s = llList2String(inventory_all, i);
      if (s != llGetScriptName()) {
         // tell the target to remove something
         llSayAll(-param, "REMOVE|" + (string) llGetInventoryKey(s) + "|" + s);
      }
   }
}

default {
   state_entry() {
      //llOwnerSay(llGetScriptName() + " used=" + (string) llGetUsedMemory() + " free=" + (string) llGetFreeMemory());

      initialize();

      if (my_role != ROLE_DELIVERY) {
         handle_anything();
      }
   }

#ifdef DEBUG
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
         HT_ITERATE(states, dump_states, "");
      }
   }
#endif

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
            HT_ITERATE(states, force_remove, 0);
         }
      }

      if (adding_count_down) {
         adding_count_down--;
         if (adding_count_down == 0) {
            HT_ITERATE(states, force_readd, 0);
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
         if (count_of([UNKNOWN_STRING, READY_REMOVE_STRING, REMOVING_STRING]) == 0 &&
               count_of([READY_ADD_STRING]) > 0) {
            // TODO FIX original code did NOT set do_resets here, and did only one add
            // is expanding this bad?!?!?
            HT_ITERATE(states, do_adds, "");
         }
         else if (my_role != ROLE_DELIVERY) {
            handle_anything();
         }
         lastchange = llGetUnixTime();
      }

      if (need_resets && count_of([UNKNOWN_STRING, READY_REMOVE_STRING, REMOVING_STRING, READY_ADD_STRING, ADDING_STRING]) == 0) {
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

#ifndef DEBUG
   object_rez(key unused_id) {
      llIfDebugSay("::object_rez(" + (string) unused_id + ")");
      llIfDebugSay("successful rez of " + llKey2Name(unused_id));
   }
#endif

   on_rez(integer param) {
      llIfDebugSay("::on_rez(" + (string) param + ")");

      initialize();

      integer i;
      integer max;
      string s;

      if (param < 0) {
         // tell the target to remove stuff
         target_remove(param);
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
                        //llSay(DEBUG_CHANNEL, "Updating pkg.o script.\nThis can generate a stack/heap collision.\nThis is safe to ignore.");
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
         if (contains(name)) {
            HT_DELETE(states, name);
            llRemoveInventory(name);
         }

         HT_ITERATE(states, do_adds, "");
      }
      if (msg == "READY") { // a ROLE_PACKAGE has completed adding to us
         HT_SET(states, name, OK_STRING);
      }
      if (msg == "RESET") {
         llResetScript();
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
