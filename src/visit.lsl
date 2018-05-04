// script used to hop around from sim to sim for updates
// nowhere near as effective as the 'bot, but it may be
// useful some day.

integer i = 0;
integer max;
key num;
key lid;

default {
   state_entry () {
      llRequestPermissions(llGetOwner(), PERMISSION_TELEPORT | PERMISSION_TAKE_CONTROLS);
   }

   run_time_permissions(integer perm) {
      if (perm & PERMISSION_TELEPORT) {
         num = llGetNumberOfNotecardLines(llGetInventoryName(INVENTORY_NOTECARD, 0));
      }
      if (perm & PERMISSION_TAKE_CONTROLS) {
         llTakeControls(CONTROL_FWD, TRUE, TRUE);
      }
   }

   timer() {
      llSetTimerEvent(0);
      i++;
      if (i < max) {
         lid = llGetNotecardLine(llGetInventoryName(INVENTORY_NOTECARD, 0), i);
      }
   }

   dataserver(key qid, string dat) {
      if (qid == num) {
         i = 0;
         max = (integer) dat;
         lid = llGetNotecardLine(llGetInventoryName(INVENTORY_NOTECARD, 0), i);
      }
      else if (qid == lid) {
         llRequestSimulatorData(dat, DATA_SIM_POS);
      }
      else {
         llSetTimerEvent(20);
         llTeleportAgentGlobalCoords(llGetOwner(), (vector) dat, <llFrand(256.0),llFrand(256.0),1023>, ZERO_VECTOR);
      }
   }
}
