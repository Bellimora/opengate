// ogos-chord

#include "global.h"
#include "objdesc.lsl"

#include "shrink.lsl"

#define MAXLISTSIZE 40
#define THROTTLE_RESERVE 20
#define THROTTLE_MAX 25

key handle_post = NULL_KEY;

string me = "";
list fingers;
string pre = "";
integer spot = 0;
string lastrequest = "";

integer last_contact;
integer next_queue;
integer next_chord;
integer next_mailcheck;
integer next_phonehome;

list queue;

#ifdef DEBUG
integer incoming_mail = 0;
#endif

key get_count = NULL_KEY;
key get_line = NULL_KEY;
key get_displayname = NULL_KEY;
string displayname;
integer last_seed = 0;

float llhttprequest_throttler = THROTTLE_MAX;

#include "prune.lsl"

#include "modget.lsl"

#include "modput.lsl"

#include "modkill.lsl"

#include "between.lsl"

#define PRE_SANITY \
   if (-1 == llSubStringIndex(pre, "@") || llGetSubString(pre,0,35) == llGetSubString(me,0,35)) { \
      pre = ""; \
   }

string seedname() {
   if (NULL_KEY != llGetInventoryKey(".ogos-seeds")) {
      return ".ogos-seeds";
   }
   return ">ogos-seeds";
}

string requesturl(string x) {
   string ret = url_part(x);
   lastrequest = x;

   if (-1 == llSubStringIndex(ret, "http://")) {
      // this should never, ever happen!
      // substitute some random bogus thing so it will fail miserably but properly.
      ret = "http://" + llMD5String((string)llFrand(1.0),0) + ".com/" + llMD5String((string)llFrand(1.0),0);
   }
   return ret;
}

string details() {
   return llDumpList2String([me,pre]+fingers, SEP2);
}

void enqueue(string url) {
   if (llGetListLength(queue) < MAXLISTSIZE) {
      if (url != me && url != "" &&
            -1 != llSubStringIndex(url, "!") &&
            -1 == llListFindList(queue, [ url ]) &&
            -1 == llListFindList(fingers, [ url ])) {
         queue = queue + [ url ];
      }
   }
}

void newnextpre(list toes) {
   toes = prune([pre, me] + toes + fingers);

   string lo = modget(me, toes, -1);
   string hi = modget(me, toes, 1);

   if (between(pre, lo, me)) {
      enqueue(lo);
   }
   if (between(me, hi, modget(me, fingers, 1))) {
      enqueue(hi);
   }
}

void process_body(string body) {
   if (body != "") { // should ALWAYS be true, but sometimes isn't.  TODO: figure out why
      list toes = llParseStringKeepNulls(body, [ SEP2 ], []);
      string them = llList2String(toes, 0);
      string thempre = llList2String(toes, 1);
      toes = llDeleteSubList(toes, 0, 1);

      if (them != me) {
         // special case, we're virginal
         if (llGetListLength(fingers) <= 1) {
            fingers = prune([them, me, thempre] + toes);
         }

         // special case, we have no pre
         if (pre == "") {
            pre = modget(me, fingers, -1);
            PRE_SANITY;
         }

         // are they our new next?
         if (between(me, them, modget(me, fingers, 1))) {
            fingers = prune([ me, them ] + fingers);
            string last = modget(me, fingers, -1);
            if (last != me && last != them) {
               fingers = modkill(me, fingers, -1);
            }
            spot = 0;
         }

         // are they our new pre?
         if (pre == "" || between(pre, them, me)) {
            pre = them;
            PRE_SANITY;
         }

         // do they know anyone who might be better next or pre?
         newnextpre([thempre]+toes);

         /// BEGIN
         integer f_them = llListFindList(fingers, [ them ]);

         if (-1 != f_them) {
            // we have them somewhere
            integer f_me = llListFindList(fingers, [ me ]);
            if (f_me > f_them) {
               f_them += llGetListLength(fingers);
            }

            integer skip = f_them - f_me;

            // if they are our fingers[skip], then
            // their toes[skip] is our fingers[skip+1]

            string tmp = modget(them, toes, skip);
            if (skip <= llGetListLength(toes) && between(me, them, tmp)) {
               // we haven't wrapped yet...
               if (llGetListLength(fingers) && llGetListLength(fingers) > skip) {
                  if (modget(me, fingers, skip+1) != modget(them, toes, skip)) {
                     fingers = prune([ me ] +
                           modput(me, fingers, skip+1, modget(them, toes, skip)));
                     if (modget(me, fingers, skip+1) != me) {
                        fingers = prune([ me ] +
                              modkill(me, fingers, skip+2));
                     }
                     spot = 0;
                  }
               }
               else {
                  fingers = prune([tmp] + fingers);
               }
            }
            else {
               // we've wrapped...
               while (llGetListLength(fingers) > (skip+2)) {
                  // trim off any excess...
                  fingers = prune([ me ] +
                        modkill(me, fingers, -1));
               }
            }
         }
      }
   }
}

#ifdef DEBUG
integer last_textish = -1;
void textish() {
   integer i;
   string s = "";
   string t;
   integer x;

   if (hasflag("textish")) {
      last_textish = 1;
      if (llGetListLength(fingers)) {
         x = (spot + llListFindList(fingers, [me]) + llGetListLength(fingers) - 1) % llGetListLength(fingers);
      }

      for (i = 0; i < llGetListLength(fingers); i++) {
         t = llList2String(fingers, i);
         if (i == x) {
            s = s + "=> ";
         }
         if (t == me) {
            s = s + llGetSubString(pre,0,7) + "*";
         }
         t = llGetSubString(t, 0, 7);
         s = s + t;
         if (i == x) {
            s = s + " <=";
         }
         s = s + "\n";
      }
      s = s + "(" + (string) llGetListLength(queue) + "/" +
         (string) incoming_mail + ")";
      llSetText(s, <1.0,1.0,1.0>,1.0);
   }
   else if (last_textish) {
      last_textish = 0;
      llSetText(s, <1.0,1.0,1.0>,1.0);
   }
}
#endif

void ontime() {
   integer now = llGetUnixTime();

   if (llhttprequest_throttler < THROTTLE_MAX) {
      llhttprequest_throttler += 1.25;
   }

   // check last_contact for possible url loss
   if ((now - last_contact) > 2500) {
      llResetScript();
   }

   // check for new email
   if (llGetListLength(queue) < MAXLISTSIZE &&
         now > next_mailcheck) {
      next_mailcheck = now + MAILCHECK_PERIOD_MIN + (integer) llFrand(MAILCHECK_PERIOD_JITTER);
      llGetNextEmail("", "");
   }

   // process an item from the queue
   // important not to enter this block if we're still waiting
   // for a previous response
   if (handle_post == NULL_KEY &&
         llhttprequest_throttler > THROTTLE_RESERVE &&
         llGetListLength(queue) && now > next_queue) {
      next_queue = now + QUEUE_PERIOD_MIN + (integer) llFrand(QUEUE_PERIOD_JITTER);
      llhttprequest_throttler -= 1.0;
      handle_post = llHTTPRequest(requesturl(llList2String(queue, 0)),
            [HTTP_METHOD, "POST"], details());
      queue = llDeleteSubList(queue, 0, 0);
   }

   // important not to enter this block if we're still waiting
   // for a previous response
   if (handle_post == NULL_KEY &&
         llhttprequest_throttler > THROTTLE_RESERVE &&
         now  > next_chord) {
      next_chord = now + CHORD_PERIOD_MIN + (integer) llFrand(CHORD_PERIOD_JITTER);

      if (llGetListLength(fingers) > 1) {
         if (spot > llGetListLength(fingers)) {
            spot = 0;
         }

         if (me != modget(me, fingers, spot)) {
            llhttprequest_throttler -= 1.0;
            handle_post = llHTTPRequest(requesturl(modget(me, fingers, spot)),
                  [HTTP_METHOD, "POST"], details());
         }
         else if (llStringLength(pre)) {
            llhttprequest_throttler -= 1.0;
            handle_post = llHTTPRequest(requesturl(pre),
                  [HTTP_METHOD, "POST"], details());
         }
         spot++;
      }
      else {
         get_count = llGetNumberOfNotecardLines(seedname());
      }
   }

   // important not to enter this block if we're still waiting
   // for a previous response
   if (handle_post == NULL_KEY &&
         llhttprequest_throttler > THROTTLE_RESERVE &&
         now > next_phonehome) {
      next_phonehome = now + PHONEHOME_PERIOD_MIN + (integer) llFrand(PHONEHOME_PERIOD_JITTER);
      llhttprequest_throttler -= 1.0;
      string image_guid = "";
      if (llGetInventoryNumber(INVENTORY_TEXTURE)) {
         image_guid = "&image=" + (string) llGetInventoryKey(llGetInventoryName(INVENTORY_TEXTURE, 0));
      }
      handle_post = llHTTPRequest("http://ma8p.com/~opengate/chord9/seed.cgi" +
            "?OBJECT_DESC=" + llEscapeURL(llGetObjectDesc()) +
            "&rev=" + llEscapeURL(llGetInventoryName(INVENTORY_BODYPART, 0)) +
            "&prims=" + (string) llGetNumberOfPrims() +
            "&OWNER_DISPLAY_NAME=" + llEscapeURL(displayname) +
            image_guid
            ,
            [HTTP_METHOD, "POST"], details());
      get_displayname = llRequestDisplayName(llGetOwner());
   }

   if (llFrand(10000.0) <= 1.0) {
      get_count = llGetNumberOfNotecardLines(seedname());
   }

#ifdef DEBUG
   textish();
#endif
}

default {
   state_entry() {
      llRequestURL();
      llSetTimerEvent(1.0);
      last_contact = llGetUnixTime();
   }

   timer() {
      ontime();
   }

   on_rez(integer unused_start_param) {
      llResetScript();
   }

   changed(integer change) {
      if (change & 0x700) { // REGION | TELEPORT | REGION_START
         llResetScript();
      }
   }

   http_response(key id, integer status, list unused_meta, string body) {
      if (id == handle_post) {
         handle_post = NULL_KEY; // we got our response!
         if (status == 200) {
            process_body(body);
         }
         else {
            integer j = llListFindList(fingers, [ lastrequest ]);
            if (-1 != j) {
               fingers = llDeleteSubList(fingers, j, j);
            }
            if (pre == lastrequest) {
               pre = modget(me, fingers, -1);
               PRE_SANITY;
            }

#ifdef DEBUG
            if (hasflag("debug:chord")) {
               llDebugSay((string)status + " response from " + lastrequest);
            }
#endif
            send(me, "email", key_part(lastrequest) , me, "");

            lastrequest = "";
         }
      }
   }

   http_request(key id, string method, string body) {
      last_contact = llGetUnixTime();
      if (method == URL_REQUEST_GRANTED) {
         me = (string)llGetKey() + SEP1 + shrink(body);
         fingers = [ me ];
         get_count = llGetNumberOfNotecardLines(seedname());
      }
      else if (method == URL_REQUEST_DENIED) {
         llSleep(1.0);
         llResetScript();
      }
      else if (method == "POST") {
         llHTTPResponse(id, 200, details());
         process_body(body);
      }
      else if (method == "GET") {
         string path = llGetHTTPHeader(id,"x-path-info");
         string query = llGetHTTPHeader(id,"x-query-string");

#ifdef DEBUG
         if (hasflag("debug:chord")) {
            llDebugSay("recv GET "+path+"?"+query);
         }
#endif

         llHTTPResponse(id, 200, details());
         process_body(body);

         if (-1 == llSubStringIndex(query, "@")) {
            string hop = modget(query, prune([ query ] + fingers), -1);
            if (hop == me) {
               llMessageLinked(LINK_THIS, MESG_RECV, llGetSubString(path, 1, -1), me);
            }
            else {
               // TODO accounting to avoid throttling
#ifdef DEBUG
               if (hasflag("debug:chord")) {
                  llDebugSay("send(0) GET " + url_part(hop) + path + "?" + query);
               }
#endif
               llhttprequest_throttler -= 1.0;
               if (0 == llSubStringIndex(url_part(hop), "http://")) {
                  llHTTPRequest(
                        url_part(hop) + path + "?" + query,
                        [HTTP_METHOD, "GET"], details());
               }
            }
         }
         else {
            llMessageLinked(LINK_THIS, MESG_RECV, llGetSubString(path, 1, -1), query);
         }
      }
   }

   link_message(integer sender, integer num, string str, key id) {
      string kay = (string) id;

      if (num == MESG_SEND) {

         // special cases

         if (kay == "--") {
            kay = pre;
         }
         if (kay == "++") {
            kay = modget(me, fingers, 1);
         }
         if (kay == "me") {
            kay = me;
         }

         // more special cases...

         list strl = llParseStringKeepNulls(str, ["/"], []);
         // TODO FIX this can be optimized with findlist
         integer i;
         for (i = 0; i < llGetListLength(strl); i++) {
            if (llList2String(strl, i) == "me") {
               strl = llListReplaceList(strl, [ me ], i, i);
            }
            if (llList2String(strl, i) == "--") {
               strl = llListReplaceList(strl, [ pre ], i, i);
            }
            if (llList2String(strl, i) == "++") {
               strl = llListReplaceList(strl, [ modget(me, fingers, 1) ], i, i);
            }
         }
         str = llDumpList2String(strl, "/");

         // and one more bizarro case...

         if (kay == me && "iam" == llList2String(strl, 0)) {
            // never send "iam" messages to myself!
            return;
         }

#ifdef DEBUG
         if (hasflag("debug:chord")) {
            llDebugSay("sending... '" + kay + "' => '" + str + "'");
         }
#endif

         // possible formats for kay:
         // direct messages:  <key>@<url>
         // indirect messages: <to>

         string hop;

         if (-1 != llSubStringIndex(kay, "@")) { // direct
            if (kay == me) { // for me
#ifdef DEBUG
               if (hasflag("debug:chord")) {
                  llDebugSay("send(1) GET " + url_part(kay) + "/" + str + "?" + me);
               }
#endif
               llMessageLinked(LINK_THIS, MESG_RECV, str, me);
            }
            else { // not for me
               // TODO accounting to avoid throttling
#ifdef DEBUG
               if (hasflag("debug:chord")) {
                  llDebugSay("send(2) GET " + url_part(kay) + "/" + str + "?" + me);
               }
#endif
               llhttprequest_throttler -= 1.0;
               if (0 == llSubStringIndex(url_part(kay), "http://")) {
                  llHTTPRequest(
                        url_part(kay) + "/" + str + "?" + me,
                        [HTTP_METHOD, "GET"], details());
               }
            }
         }
         else if (-1 != llSubStringIndex(kay, "*")) { // indirect broadcast
            kay = strreplace(kay, "*", "");

            for (i = 0; i < llGetListLength(fingers); i++) {
               hop = llList2String(fingers, i);

               if (hop != me) { // not for me
                  // TODO accounting to avoid throttling
#ifdef DEBUG
                  if (hasflag("debug:chord")) {
                     llDebugSay("send(3) GET " + url_part(hop) + "/" + str + "?" + kay);
                  }
#endif
                  llhttprequest_throttler -= 1.0;
                  if (0 == llSubStringIndex(url_part(hop), "http://")) {
                     llHTTPRequest(
                           url_part(hop) + "/" + str + "?" + kay,
                           [HTTP_METHOD, "GET"], details());
                  }
               }
            }
         }
         else { // indirect
            hop = modget(kay, prune([ kay ] + fingers), -1);
            if (hop == me) { // for me
               llMessageLinked(LINK_THIS, MESG_RECV, str, me);
            }
            else { // not for me
               // TODO accounting to avoid throttling
#ifdef DEBUG
               if (hasflag("debug:chord")) {
                  llDebugSay("send(4) GET " + url_part(hop) + "/" + str + "?" + kay);
               }
#endif
               llhttprequest_throttler -= 1.0;
               if (0 == llSubStringIndex(url_part(hop), "http://")) {
                  llHTTPRequest(
                        url_part(hop) + "/" + str + "?" + kay,
                        [HTTP_METHOD, "GET"], details());
               }
            }
         }
      }
      else if (num == MESG_RECV) {
         // TODO anything?
#ifdef DEBUG
         if (hasflag("debug:chord")) {
            llDebugSay("MESG_RECV "+(string)sender+" "+(string)num+" '"+str+"' '"+(string)id+"'");
         }
#endif
      }
   }

   email(string unused_t, string unused_a, string s, string unused_m, integer n) {
      // TODO verify address, make sure it is from SL!

      enqueue(s);

#ifdef DEBUG
      incoming_mail = n;

      textish();
#endif

      if (n) {
         llGetNextEmail("", "");
      }
   }

   dataserver(key id, string data) {
      if (id == get_count) {
         get_line = llGetNotecardLine(seedname(), (integer) llFrand((float) data));
      }
      else if (id == get_line) {
         last_seed = llGetUnixTime();

         send(me, "email", data, me, "");

#ifdef DEBUG
         textish();
#endif
      }
      else if (id == get_displayname) {
         displayname = data;
      }
   }
}
