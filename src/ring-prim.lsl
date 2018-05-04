// transportPrim.lsl
// openrings transport prim script
//
// Open Stargate Project
// Copyright (C) 2007-2013 Adam Wozniak, Doran Zemlja, and CB Radek
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    PLEASE READ THE README FILE
//
////////////////////////////////////////////////////////////////////////////////////////////////

#include "global.h"

//integer debug = 0;

vector originalLocation;
vector tempLocation;
vector destinationLocation;

rotation destinationRotation;

key destinationKey;
key sourceKey;
key transportKey;

list avList;
list destination_list;
list message_list;

integer listen_handle;
integer listen_channel;

string messageTO;
string messageFROM;
string messageCOMMAND;

string animation = "";

setLinkTexture(string texture)
{
   integer i;
   integer tempNum = llGetNumberOfPrims();
   for (i = 0; i<tempNum+1; i++)
   {
      if (llGetAgentSize(llGetLinkKey(i)) == ZERO_VECTOR)
      {
         llSetLinkTexture(i, texture, ALL_SIDES);
      }
   }
}

ResetTransportPrim()
{
   llVolumeDetect(TRUE);

   // need to load the texture for the transport beam early so it shows up correctly when called via MakeParticles()
   llSetTexture("Smoke", 1);
   //llSetTexture("2d1cc751-383e-910a-dc3c-c8793bacf90c", 0);

   //    setLinkTexture("Smoke");

   originalLocation = llGetPos();
   tempLocation = originalLocation;
   destinationLocation = tempLocation;
   destinationKey = NULL_KEY;
   sourceKey = NULL_KEY;
   avList = [];

   message_list = [];
   messageTO = "";
   messageFROM = "";
   messageCOMMAND = "";
   transportKey = llGetKey();
}

default
{
   state_entry()
   {
      if (llGetInventoryNumber(INVENTORY_BODYPART) != 0) {
         return;
      }

      ResetTransportPrim();
      listen_channel = llGetStartParameter();
      listen_handle = llListen(listen_channel, "", "", "");

      llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE, PRIM_GLOW, ALL_SIDES, 0.5]);

      llSetTimerEvent(45); // how long to wait for av to sit on prim before dying
      llSay(0, "Touch prim to prepare for transport.");
   }
   timer()
   {
      integer i;
      llSetTimerEvent(0); //  (to stop the timer)
      llSay(0, "Wait time exceeded, resetting script...");

      for (i=0; i < llGetListLength(avList); i++)
      {
         llUnSit((key)llList2Key(avList, i));
      }

      llRegionSay(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":transportPrimDead");
      llDie();
   }
   listen( integer unused_channel, string unused_name, key unused_id, string message )
   {
      integer i;

      //if(debug) llSay(0, message);

      message_list = llParseString2List(message, [":"], [""]);

      messageTO = llList2String(message_list, 0);
      messageFROM = llList2String(message_list, 1);
      messageCOMMAND = llList2String(message_list, 2);

      if (messageTO == (string)transportKey)
         // only listen to those who know us
      {
         if (messageCOMMAND == "ringDest")
            // this command is whispered from source platform
         {
            sourceKey = (key)messageFROM;
            destinationKey = (key)llList2Key(message_list, 3);

            // ringList was already cleaned for deleted rings. if we don't get a valid position
            // keep trying til valid. Seems to be a server lag issue.
            do {
               destination_list = llGetObjectDetails(destinationKey, [ OBJECT_POS, OBJECT_ROT ]);
               destinationLocation = llList2Vector(destination_list, 0);
               destinationRotation = llList2Rot(destination_list, 1);
            } while (destinationLocation == ZERO_VECTOR);


            llSetTimerEvent(0);//   (to stop the timer)
            setLinkTexture("Transparent");
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
            originalLocation = llGetPos();

            llSay(0, "Locked on.");

            // Tell Platform to activate rings
            llWhisper(listen_channel,
                  (string)sourceKey + ":" +
                  (string)transportKey + ":" +
                  "rezRings");
         }
         else if (messageCOMMAND == "commenceTransport")
         {
            // Tell Platforms to emit particles
            llWhisper(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":emitParticles");
            llRegionSay(listen_channel, (string)destinationKey + ":" + (string)transportKey + ":incomingTransport");

            llSleep(2); // give the platforms a sec to rez their rings.

            //if (debug) llSay(0, "DEBUG:" + (string)destinationLocation);

            // let anyone who wants to come along do so.
            llRegionSay(0x52696e67, llDumpList2String([llGetPos()+<0.0,0.0,-1.5>, llGetRot(), destinationLocation, destinationRotation], "|"));

            llSetRot(destinationRotation); // rotate to destination's set rotation
            // Warp to destination
            llSetRegionPos(destinationLocation+<0.0,0.0,1.5>);

            llSleep(0.2); // Seems to help rezing extra rings on arrival (rare)

            for (i=0; i < llGetListLength(avList); i++)
            {
               llUnSit((key)llList2Key(avList, i));
            }

            llRegionSay(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":transportPrimDead");
            llWhisper(listen_channel, (string)destinationKey + ":" + (string)transportKey + ":transportPrimDead");

            llDie();
         }
         else if (messageCOMMAND == "abortTransport")
         {
            for (i=0; i < llGetListLength(avList); i++)
            {
               llUnSit((key)llList2Key(avList, i));
            }

            llDie();
         }
         else if (messageCOMMAND == "setTempOnRez")
         {
            if (llList2String(message_list, 3) == "TRUE")
            {
               llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
            }
            else
            {
               llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
            }
         }
      }
   }

   changed(integer change)
   {
      key tempKey;
      integer numPrims;
      integer i;

      if (change & CHANGED_LINK)
      {
         numPrims = llGetNumberOfPrims();
         avList = [];
         for (i=0; i < numPrims+1; i+=1)
         {
            tempKey = llGetLinkKey(i);
            if (llGetAgentSize(tempKey) != ZERO_VECTOR)
            {
               avList += [ tempKey ];
               llRequestPermissions(tempKey, PERMISSION_TRIGGER_ANIMATION);
            }
         }
      }
   }

   run_time_permissions(integer perm)
   {
      if (perm & PERMISSION_TRIGGER_ANIMATION)
      {
         llStopAnimation("sit");
         animation="stand";//llGetInventoryName(INVENTORY_ANIMATION,0);
         llStartAnimation(animation);
      }
   }
}
