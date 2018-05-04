// very simple tracker script for initial peer discovery

list peers;
integer maxpeers = 20;

default {
   state_entry() {
      llSetObjectDesc((string) llGetKey());
      llSetTimerEvent(1.0);
   }

   timer() {
      llGetNextEmail("", "");
   }

   touch_start(integer num) {
      llOwnerSay("==\n" + llDumpList2String(peers, "\n"));
   }

   // we assume the address is "<key>@<something>" and the subject is a complete URL
   email(string time, string address, string subject, string message, integer num_left) {
      integer n;

      address = llList2String(llParseString2List(address, [ "@" ], []), 0);

      if (0 == llSubStringIndex(subject, address + "@")) {
         n = llListFindList(peers, [ message ]);

         if (n != -1) {
            peers = llDeleteSubList(peers, n, n);
         }

         peers = peers + message;

         if (llGetListLength(peers) > maxpeers) {
            peers = llDeleteSubList(peers, 0, 0);
         }

         // we don't care about the reply,
         // so we don't save the handle,
         // and we don't have a http_response event
         llHTTPRequest(subject, [HTTP_METHOD, "POST"], llDumpList2String(peers, "|"));
      }

      if (num_left) {
         llGetNextEmail("", "");
      }
   }
}
