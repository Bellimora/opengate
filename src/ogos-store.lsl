// ogos-store

#undef DEBUG

#include "global.h"

// This script is intentionally lightweight;
// we want ALL our memory to be used for storage!

#define SIZE 60
#define STRIDE 2
#define MAXPERHASH 8

string lastreqid;
list storage;

default {
   on_rez(integer unused_start_param) {
      llResetScript();
   }

   link_message(integer unused_sender, integer num, string mesg, key unused_id) {
      if (num == MESG_RECV) {
         list pieces = llParseStringKeepNulls(mesg, ["/"], []);
         string arg0 = llList2String(pieces, 0);

         if (arg0 == "store" || arg0 == "copy") {
            string hashkey = llList2String(pieces, 1);
            string val = llList2String(pieces, 2);
            integer i = llListFindList(storage, [ hashkey, val ]);
            integer l;
            integer count;
            integer max;

            if (i == -1) {
               storage = [ hashkey, val ] + storage;
            }
            else {
               storage = [ hashkey, val ] + llDeleteSubList(storage, i, i + STRIDE - 1);
            }

            // BEGIN TODO: take hashkey precedence into account here

            // make sure we still have room...
            max = llGetListLength(storage);
            count = 0;
            for (i = 0; i < max; i += STRIDE) {
               if (hashkey == llList2String(storage, i)) {
                  count++; // keep count of occurances of this hashkey
                  l = i; // and the oldest occurance of this hashkey
               }
            }

            // trim if too many for this hash
            if (count > MAXPERHASH) {
               // delete the oldest
               storage = llDeleteSubList(storage, l, l + STRIDE - 1);
            }

            // END TODO: take hashkey precedence into account here

            // trim if too many altogether
            if (llGetListLength(storage) > (SIZE * STRIDE)) {
               storage = llList2List(storage, 0, -STRIDE - 1);
            }

            // neighbors get copies, in case we die
            if (arg0 == "store") {
               send("--", "copy", hashkey, val);
               send("++", "copy", hashkey, val);
            }
         }
         else if (arg0 == "fetch" || arg0 == "carry" || arg0 == "vend") {
            string k = llList2String(pieces, 1);
            string to = llList2String(pieces, 2);
            string reqid = llList2String(pieces, 3);
            integer max = llGetListLength(storage);
            integer i;
            integer sends;

            if (reqid != lastreqid) { // avoid multiple responses

               lastreqid = reqid;

               for (i = 0; i < max; i += STRIDE) {
                  if (llList2String(storage, i) == k) {
                     if (arg0 == "vend") {
                        // special case, vending
                        send(llList2String(storage, i+1), "vendor", to, reqid, k);
                     }
                     else {
                        // normal case
                        send(llList2String(storage, i+1), "tell", to, reqid, k);
                     }
                     sends++;
                  }
               }

               if (arg0 != "vend") {
                  if (!sends) {
                     send(to, "notfound", reqid, k);
                  }

                  // our neighbors may know things we do not
                  if (arg0 == "fetch") {
                     send("--", "carry", k, to, reqid);
                     send("++", "carry", k, to, reqid);
                  }
               }
            }
         }
      }
   }
#ifdef DEBUG
   touch_start(integer unused_num) {
      integer i;
      integer max = llGetListLength(storage);
      for (i = 0; i < max; i += STRIDE) {
         llOwnerSay("store:" + llDumpList2String(llList2List(storage, i, i + STRIDE - 1), "=>"));
      }
   }
#endif
}
