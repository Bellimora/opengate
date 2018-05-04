// ring-follow.lsl, object transportation script for SecondLife
//
// Drop this script into any object, it will follow the transporter
// prim when the rings are activated.
//
// Copyright (C) 2011-2013 Adam Wozniak and Doran Zemlja
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

default {
   state_entry() {
      llListen(0x52696e67, "", NULL_KEY, "");
   }
   listen(integer unused_channel, string unused_name, key unused_id, string mesg) {
      vector src_pos   = (vector) llList2String(llParseString2List(mesg, ["|"], []), 0);
      rotation src_rot = (rotation) llList2String(llParseString2List(mesg, ["|"], []), 1);
      vector dst_pos   = (vector) llList2String(llParseString2List(mesg, ["|"], []), 2);
      rotation dst_rot = (rotation) llList2String(llParseString2List(mesg, ["|"], []), 3);

      // calculate our offset from center, and adjust for rotation...
      vector delta = ((llGetPos() - src_pos) / src_rot) * dst_rot;

      if (llVecMag(delta) < 6.0) {
         llSetRegionPos(dst_pos+delta);
         // adjust our final rotation...
         llSetRot((llGetRot() / src_rot) * dst_rot);
      }
   }
}
