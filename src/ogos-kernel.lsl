// ogos-kernel

#include "global.h"

#include "objname.lsl"
#include "gods.lsl"

#include "aliases.lsl"
#include "trim.lsl"

#include "k2sl.lsl"
#include "k2ss.lsl"
#include "hasanyflag.lsl"

#include "reset.lsl"

#define ADDRDISPNUM        343532

#define ALIAS_PERIOD 3600
#define STORE_PERIOD 60

// make sure we don't overtell...
string lastreq;
string reqid;

integer storespot = 0;

list hashes;
list humans;
integer last_aliases;
key displaynamereq;
key usernamereq;
string username;
string displayname;

string radio_id = "";
integer radio_counter = 0;

integer last_store;

integer begin;

list verbs = [
"/s", "/dsgc", "/sgc",
"/dial", "/d", "dd",
"/a", "/asgard"
];

void doaliases() {
   string alias;

   hashes = [];
   humans = [];

   // Multiple levels, in order of decreasing precedence
   // blanks in precedence marked with empty string

   // unique key, symbols
   alias = k2ss(llGetKey());
   hashes = hashes + [ hash(alias) ];
   humans = humans + [ alias ];

   // unique key, letters
   alias = k2sl(llGetKey());
   hashes = hashes + [ hash(alias) ];
   humans = humans + [ alias ];

   // regionname
   alias = llGetRegionName();
   if (hasflag("default")) {
      // with {default}
      hashes = hashes + [ hash(alias), "" ];
   }
   else {
      // without {default}
      hashes = hashes + [ "", hash(alias) ];
   }
   humans = humans + [ alias ];

   // regionname username
   alias = llGetRegionName() + " " + username;
   hashes = hashes + [ hash(alias) ];
   humans = humans + [ alias ];

   // regionname displayname
   if (displayname != username) {
      alias = llGetRegionName() + " " + displayname;
      hashes = hashes + [ hash(alias) ];
      humans = humans + [ alias ];
   }
   else {
      hashes = hashes + [ "" ];
   }

   // any <> aliases and [] aliases...
   list extra;

   // gorram alias hijackers!
   if (isgod(llGetOwner())) {
      // god aliases
      extra = aliases(0, "<", ">");
   }
   else {
      // something random but potentially useful
      extra = [ (string) llGetKey() ];
   }

   extra = extra + aliases(0, "[", "]");

   integer i;
   integer max = llGetListLength(extra);
   for (i = 0; i < max; i++) {
      alias = llList2String(extra, i);
      hashes = hashes + [ hash(alias) ];
      humans = humans + [ alias ];
   }

   // request again, for the next pass...
   displaynamereq = llRequestDisplayName(llGetOwner());
   usernamereq = llRequestAgentData(llGetOwner(), DATA_NAME);
}

void handle_verb(string dest) {
   if (llGetUnixTime() - begin < 30) {
      llSay(0, "Wait (initializing, " + (string) (30 - (llGetUnixTime() - begin)) + " seconds left)");
   }
   else if (hasflag("secure")) {
      llSay(0, "This gate has been secured, and will not dial out.");
   }
   else {
      send("me", "verb", dest);
   }
}

default {
   state_entry() {
      begin = llGetUnixTime();
      displaynamereq = llRequestDisplayName(llGetOwner());
      usernamereq = llRequestAgentData(llGetOwner(), DATA_NAME);
      llSetTimerEvent(1);
      llListen(0, "", NULL_KEY, "");
      llListen(123, "", NULL_KEY, "");
      llListen(34353, "", NULL_KEY, "");
      llListen(ADDRDISPNUM, "", NULL_KEY, "ping");
      llListen(RADIONUM, "", NULL_KEY, "");
   }

   timer() {
      integer now = llGetUnixTime();

      reset();

      if (radio_counter) {
         radio_counter--;
      }

      if ((now - last_aliases) > ALIAS_PERIOD) {
         last_aliases = now;

         doaliases();
      }

      if ((now - last_store) > STORE_PERIOD) {
         last_store = now;

         if (storespot >= llGetListLength(hashes)) {
            storespot = 0;
         }

         string alias = llList2String(hashes, storespot);
         if (llStringLength(alias)) {
            send(alias, "store", alias, "me");
            if (hasflag("debug")) {
               llDebugSay("storing alias " + alias);
            }
         }

         storespot++;
      }
   }

   listen(integer chan, string unused_name, key unused_id, string mesg) {
      integer max = llGetListLength(verbs);
      integer i;
      string verb;
      string dest;
      string hach;

      // convert from old dhd
      if (chan == 34353) {
            mesg = strreplace(mesg, " random", "");
      }

      // address display

      if (chan == ADDRDISPNUM) {
         llWhisper(ADDRDISPNUM, "pong");
         return;
      }

      // radio

      if (chan == RADIONUM && radio_counter) {
         send(radio_id, "radio", mesg);
         return;
      }

      // dialing verbs...

      if (-1 != llListFindList(verbs, [ mesg ])) {
         // exactly and precisely the verb
         handle_verb("");
      }
      else {
         for (i = 0; i < max; i++) {
            verb = llList2String(verbs, i);
            if (0 == llSubStringIndex(mesg, verb + " ") || 0 == llSubStringIndex(mesg, verb + ":")) {
               // <verb>[ :]<destination>
               dest = llToLower(llGetSubString(mesg, llStringLength(verb) + 1, -1));
               dest = trim(dest);
               handle_verb(dest);
            }
         }
      }

      // debugging

      verb = "/track ";
      if (0 == llSubStringIndex(mesg, verb)) {
            dest = llToLower(llGetSubString(mesg, llStringLength(verb), -1));
            hach = hash(dest);
            llResetTime();
            send(hach + "*", "tell", "me", hash((string)llFrand(1.0)), hach);
      }
   }

   on_rez(integer unused_start_param) {
      llResetScript();
   }

   link_message(integer unused_sender, integer num, string mesg, key id) {
      if (num == MESG_RECV) {
         list pieces = llParseStringKeepNulls(mesg, ["/"], []);
         string arg0 = llList2String(pieces, 0);

         if (arg0 == "rand") {
            if (!hasflag("norandom") && 
               !hasflag("restricted") &&
               !hasflag("sopv") &&
               !hasflag("secure") &&
               !hasanyflag("err_")) {
               arg0 = "tell"; // sneaky spoofage
            }
            else {
               string newreq = llList2String(pieces, 2);
               if (lastreq != newreq) {
                  lastreq = newreq;
#ifdef DEBUG
                  if (hasflag("debug")) {
                     llDebugSay("bouncing random");
                  }
#endif
                  send("++", "rand", llList2String(pieces, 1), llList2String(pieces, 2), llList2String(pieces,3));
               }
            }
         }
         if (arg0 == "tell") {
            string newreq = llList2String(pieces, 2);
            if (lastreq != newreq) {
               lastreq = newreq;
               if (!hasflag("secure")) {
                  send(llList2String(pieces, 1),
                     "iam", llList2String(pieces, 2),
                     llList2String(pieces, 3),
                     llListFindList(hashes, [ llList2String(pieces,3) ]),
                     llEscapeURL(llGetRegionName()),
                     strreplace((string)llGetPos(), " ", ""),
                     strreplace((string)llGetRot(), " ", ""),
                     llEscapeURL(llGetObjectName()));
               }
            }
         }
         if (arg0 == "lookup") {
            string hach;
            string dest = llList2String(pieces, 1);
            reqid = llList2String(pieces, 2);

            hach = hash(dest);

            //reqid = hash((string) llFrand(1.0));

            if (dest == "--" || dest == "++" || 36 == llSubStringIndex(dest, "@")) {
#ifdef DEBUG
               llResetTime();
#endif
               send(dest, "tell", "me", reqid, hach);
            }
            else if (dest == "") {
               hach = hash((string) llFrand(1.0));
#ifdef DEBUG
               llResetTime();
#endif
               send(hach + "*", "rand", "me", reqid, hach);
            }
            else {
#ifdef DEBUG
               llResetTime();
#endif
               if (dest == "random") {
                  llSay(0, "Use of 'random' is deprecated.  Try '/dial' instead.");
               }

               send(hach + "*", "fetch", hach, "me", reqid);
            }
         }
         if (arg0 == "opento") {
            send(llList2String(pieces, 1), "woosh");
            radio_id = llList2String(pieces, 1);
            radio_counter = 60;
         }
         if (arg0 == "woosh") {
            radio_id = id;
            radio_counter = 60;
         }
         if (arg0 == "radio") {
            llRegionSay(RADIONUM, llList2String(pieces, 1));
         }
         if (arg0 == "askaddr") {
            list l = [ "telladdr", llList2String(pieces, 1) ] + humans;
            sendl("me", l);
         }
         if (arg0 == "iam") {
            if (hasflag("debug")) {
               llDebugSay("\n\n\n"+(string)llGetTime()+"\nresponse from " + (string) id + "\n" + mesg + "\n\n\n\n");
            }
         }
         if (arg0 == "notfound") {
            if (hasflag("debug")) {
               llDebugSay("\n\n\n"+(string)llGetTime()+"\nresponse from " + (string) id + "\n" + mesg + "\n\n\n\n");
            }
         }
      }
   }

   touch_start(integer unused_num) {
#ifdef DEBUG
      if (hasflag("debug")) {
         llDebugSay("\n" + llDumpList2String(humans, "\n"));
      }
#endif
   }

   dataserver(key id, string data) {
      if (id == displaynamereq) {
         displayname = data;
      }
      if (id == usernamereq) {
         username = data;
         if (displayname == "") {
            displayname = username;
         }
      }
   }
}
