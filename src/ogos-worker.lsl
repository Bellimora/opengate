// ogos-worker

#include "global.h"
#include "objdesc.lsl"

#include "gods.lsl"
#include "preload.lsl"
#include "clrflag.lsl"
#include "setflag.lsl"
#include "is_locked.lsl"
#include "im.lsl"
#include "truncname.lsl"

#include "aliases.lsl"
#include "flags.lsl"
#include "setflagvalue.lsl"

#include "uniq.lsl"
#include "reset.lsl"

string lasttext = "UNKNOWN";

integer last_rez;
integer last_tryrez;

integer dlgchannel;

string lastreq;

list flaglist = [ "norandom", "secure" ];
list debuglist = [ "debug", "debug:chord", "debug:pkg", "textish", "norandom", "sopv", "err_disabled" ];

string version_info() {
   integer i;
   string s;
   list l;
   list objlist;

   s = "VERSION INFORMATION:";
   s = s + "\n" + llDumpList2String(llGetInventoryList(INVENTORY_BODYPART),"_");
   objlist = llGetInventoryList(INVENTORY_OBJECT);
   for (i = 0; i < llGetListLength(objlist); i++) {
      if (0 == llSubStringIndex(llList2String(objlist, i), "~")) {
         l = llParseString2List(llList2String(objlist, i), [ "~" ], []);
         s = s + "\n" + llList2String(l, 1) + "." + llList2String(l,2);
      }
   }
   return s;
}

void disallow_temp_on_rez() {

   // gates are designed to be permanent fixtures,
   // not temp on rez objects.

   // they don't work if they're temp-on-rez

   list l = llGetPrimitiveParams([PRIM_TEMP_ON_REZ]);
   integer i = (integer) llList2String(l, 0);

   if (i) {
      // if you remove this, I will be seriously cross
      llShout(0, "object must NOT be temp-on-rez!!!");
      llDie();
   }
}

void disallow_deed_to_group() {

   // deeding a gate to a group causes all kinds
   // of trouble with updates and maintenance

   list l = llGetObjectDetails(llGetKey(), [ OBJECT_OWNER, OBJECT_GROUP ]);
   key owner = (key) llList2String(l, 0);
   key group = (key) llList2String(l, 1);

   if (owner == NULL_KEY || owner == group) {
      // if you remove this, I will be seriously cross
      llShout(0, "object must NOT be deeded to group!!!");
      llDie();
   }
}

void disallow_attachment() {

   // gates are not meant to be attached to avatars

   // if we're attached, then ...
   // we can't llDie()
   // we can't llDetachFromAvatar() without permission
   // we can't jump to another state in a function

   // the best we can hope for is to be bloody annoying

   while (llGetAttached()) {
      // if you remove this, I will be seriously cross
      llDie();

      llShout(0, "object must NOT be attached to avatar!!!");
      llSleep(0.5);
   }
}

void disallow_linking(integer die) {

   // gates should not be linked to other objects

   // link order changes when two objects are linked together

   // gate code assumes all kinds of things about link order,
   // and will fail to function properly if the link order changes

   if (die || llGetLinkNumber() > 1) {
      // if you remove this, I will be seriously cross
      llShout(0, "object must not be linked to other objects!!!");
      llDie();
   }
}

void set_restricted() {
   // PARCEL_FLAG_USE_ACCESS_GROUP | PARCEL_FLAG_USE_ACCESS_LIST
   clrflag("restricted");
   if (llGetParcelFlags(llGetPos()) & 0x300) {
      setflag("restricted");
   }
}

void clean_old_rev() {
   list l = llGetInventoryList(INVENTORY_BODYPART);
   while (llGetListLength(l) > 1) {
      llRemoveInventory(llList2String(l, 0));
      l = llGetInventoryList(INVENTORY_BODYPART);
   }
}

void clean_name_desc() {
   list f = flags();
   list a = aliases(TRUE, "[", "]");
   list p = aliases(TRUE, "<", ">");
   string n = truncname();
   string d = "";
   string m = "";

   if (isgod(llGetOwner()) && llGetListLength(p)) {
      m = "<" + llDumpList2String(p, "><") + ">";
   }

   if (llGetListLength(a)) {
      m += "[" + llDumpList2String(a, "][") + "]";
   }

   if (llStringLength(m)) {
      n = n + " " + m;
   }

   if (llGetListLength(f)) {
      d = "{" + llDumpList2String(f, "}{") + "}";
   }

   llSetObjectName(n);
   llSetObjectDesc(d);
}

integer can_create() {
   integer parcelflags = llGetParcelFlags(llGetPos());
   list who = llGetObjectDetails(llGetKey(), [ OBJECT_OWNER, OBJECT_GROUP ]);
   list where = llGetParcelDetails(llGetPos(), [ PARCEL_DETAILS_OWNER, PARCEL_DETAILS_GROUP ]);

   // gate owner is land owner
   if (llList2String(who,0) == llList2String(where,0)) {
      clrflag("err_create");
      return 1;
   }

   // object group is land group and land allows group create
   if (llList2String(who,1) == llList2String(where,1) &&
         (parcelflags & PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS)) {
      clrflag("err_create");
      return 1;
   }

   // land allows any create
   if (parcelflags & PARCEL_FLAG_ALLOW_CREATE_OBJECTS) {
      clrflag("err_create");
      return 1;
   }

   // empirical testing
   if (last_tryrez != 0 && last_rez >= last_tryrez) {
      // we tried one, and it worked!
      clrflag("err_create");

      // if it's been too long, try again...
      if ((llGetUnixTime() - last_rez) > 24*60*60) {
         last_tryrez = 0;
      }

      return 1;
   }
   else if (last_tryrez == 0) {
      // assume we're good, but force a try just in case
      llRezObject(">reztest", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, (integer)("0x"+(string)llGetKey()));
      last_tryrez = llGetUnixTime();

      // don't clear any errors; there might be one, and we might have been reset
      return 1;
   }

   if (!hasflag("err_create")) {
      setflag("err_create");
   }

   return 0;
}

void user(key id) {
   llDialog(id, "User menu", [ "HELP", "AUTOMAPHUD", "ADDRESSES", "GET GATE", "GROUP" ], dlgchannel);
}

default {
   state_entry() {
      clrflag("err_create"); // fixes old bug // TODO remove this later...

      llSetTouchText("Help");

      llSetTimerEvent(1.0);

      disallow_deed_to_group();
      disallow_attachment();
      disallow_temp_on_rez();

      dlgchannel = (integer) llFrand(65536) + 65536;
      llListen(dlgchannel, "", NULL_KEY, "");
      llListen(124, "", NULL_KEY, "");
   }

   timer() {
      string text = "";

      reset();

      preload_ontime();

      disallow_temp_on_rez();
      set_restricted();

      clean_name_desc();

      clean_old_rev();

      if (!can_create()) {
         string msg =
            "ERROR: OpenGate at " + llGetRegionName() + " " + (string) llGetPos() + " " +
            "cannot create objects!";
         im(llGetOwner(), msg);
         llSay(0, msg);
         text = text + "ERROR: cannot create objects!\n";
      }

      if (is_locked()) {
         string msg =
            "ERROR: OpenGate at " + llGetRegionName() + " " + (string) llGetPos() + " " +
            "has been locked!";
         im(llGetOwner(), msg);
         llSay(0, msg);
         text = text + "ERROR: object locked!\n";
         setflag("err_locked");
      }
      else {
         clrflag("err_locked");
      }

      if (hasflag("err_changelinks")) {
         string msg =
            "ERROR: OpenGate at " + llGetRegionName() + " " + (string) llGetPos() + " " +
            "needs PHYS reset!";
         im(llGetOwner(), msg);
         llSay(0, msg);
         text = text + "ERROR: manual PHYS reset needed!\n";
      }

      if (hasflag("err_disabled")) {
         string msg =
            "ERROR: OpenGate at " + llGetRegionName() + " " + (string) llGetPos() + " " +
            "has been manually disabled!";
         im(llGetOwner(), msg);
         llSay(0, msg);
         text = text + "ERROR: manually disabled!\n";
      }

      // ban lines means {norandom} !
      // {norandom} is user set, use {restricted} instead

      if (text != lasttext) {
         lasttext = text;
         if (llStringLength(text)) {
            llSetText(text, <1.0,0.0,0.0>, 1.0);
         }
         else {
            llSetText(text, <1.0,1.0,1.0>, 0.0);
         }
      }
   }

   on_rez(integer unused_start_param) {
      llResetScript();
   }

   link_message(integer unused_sender, integer num, string mesg, key unused_id) {
      if (num == MESG_RECV) {
         list pieces = llParseStringKeepNulls(mesg, ["/"], []);
         string arg0 = llList2String(pieces, 0);

         if (arg0 == "email") {
            llEmail(llList2String(pieces, 1) + "@" + EMAIL_HOST, llList2String(pieces,2), llList2String(pieces,3));
         }
         else if (arg0 == "preload") {
            preload_parse(pieces);
         }
         else if (arg0 == "telladdr") {
            key who = (key) llList2String(pieces, 1);
            string s = "Addresses for this gate:\n";
            s = s + llDumpList2String(llList2List(pieces, 2, -1), "\n");
            llDialog(who, s, [ ], dlgchannel);
            llSay(0, s);
         }
         if (arg0 == "vendor") {
            integer i;
            integer max;
            string newreq = llList2String(pieces, 2);
            string name;
            if (lastreq != newreq) {
               lastreq = newreq;
               list objlist = llGetInventoryList(INVENTORY_OBJECT);
               max = llGetListLength(objlist);
               for (i = 0; i < max; i++) {
                  name = llList2String(objlist, i);
                  if (0 == llSubStringIndex(name, "opengate_") &&
                     -1 != llSubStringIndex(name, "_release")) {
                     llGiveInventory(llList2String(pieces, 1), name);
                  }
               }
            }
         }
      }
   }

   changed(integer change) {
      if (change & CHANGED_OWNER) {
         disallow_deed_to_group();
      }
      if (change & CHANGED_LINK) {
         disallow_linking(1);
      }
   }

   object_rez(key id) {
      // *sigh* SVC-3421
      if (llGetOwnerKey(id) != id) {
         last_rez = llGetUnixTime();
      }
   }

   attach(key unused_id) {
      disallow_attachment();
   }

   listen(integer chan, string unused_name, key id, string mesg) {
      if (chan == dlgchannel) {
         if (mesg == "ADMIN") {
            llDialog(id, (string) llGetKey(), [ "THEME", "FLAGS", "RESET", "DIE", "DEBUG", "+90", "-90", "+180" ], dlgchannel);
            return;
         }
         if (mesg == "+90" || mesg == "-90" || mesg == "+180") {
            llSetRot(llGetRot() * llEuler2Rot(<0,0,(integer)mesg> * DEG_TO_RAD));
         }
         if (mesg == "RESET") {
            llResetOtherScript("}pkg.o");
            llSetScriptState("}pkg.o", 1);
         }
         if (mesg == "DIE") {
            llDialog(id, "This will delete your stargate.  Are you sure?", [ "DIE!" ], dlgchannel);
            return;
         }
         if (mesg == "DIE!") {
            llDie();
            return;
         }
         if (mesg == "USER") {
            user(id);
            return;
         }
         if (mesg == "GROUP") {
            llLoadURL(id, "opengate group", "http://world.secondlife.com/group/e949df2f-ff8c-f0d3-bb17-d882466b0ddf");
         }
         if (mesg == "GET GATE") {
            send(hash("vendor") + "*", "vend", hash("vendor"), id, hash((string) llFrand(1.0)));
         }
         if (mesg == "HELP") {
            llGiveInventory(id, "help");
            return;
         }
         if (mesg == "AUTOMAPHUD") {
            llGiveInventory(id, "automaphud");
            return;
         }
         if (mesg == "THEME") {
            list notelist = llGetInventoryList(INVENTORY_NOTECARD);
            integer max = llGetListLength(notelist);
            integer i;
            list l = [];
            string s;
            for (i = 0; i < max; i++) {
               s = llList2String(notelist, i);
               if (0 == llSubStringIndex(s, "@theme:")) {
                  s = llGetSubString(s, 7, -1);
                  l += s;
               }
            }
            l = llListSort(l, 1, TRUE);
            llDialog(id, "Choose a theme:", l, dlgchannel);
            return;
         }
         if (mesg == "FLAGS") {
            llDialog(id, "set/clear flags:\n" + llGetObjectDesc(), uniq(flags() + flaglist), dlgchannel);
         }
         if (mesg == "DEBUG") {
            llDialog(id, "set/clear debugging flags:\n" + llGetObjectDesc(), uniq(flags() + debuglist), dlgchannel);
         }
         if (mesg == "ADDRESSES") {
            send("me", "askaddr", id);
         }
         if (NULL_KEY != llGetInventoryKey("@theme:"+mesg)) {
            setflagvalue("theme", mesg);
         }
         if (-1 != llListFindList(flags() + flaglist + debuglist, [ mesg ])) {
            if (hasflag(mesg)) {
               clrflag(mesg);
            }
            else {
               setflag(mesg);
            }
         }
      }
      else if (chan == 124) {
         if (isadmin(mesg)) {
            llDialog((key) mesg, version_info(), [ "ADMIN", "USER" ], dlgchannel);
         }
         else {
            user((key) mesg);
         }
      }
   }

   touch_start(integer unused_num) {
      if (isadmin(llDetectedKey(0))) {
         llDialog(llDetectedKey(0), version_info(), [ "ADMIN", "USER" ], dlgchannel);
      }
      else {
         user(llDetectedKey(0));
      }
   }
}
