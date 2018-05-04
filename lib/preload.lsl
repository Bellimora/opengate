#ifndef _INCLUDE_PRELOAD_LSL_
#define _INCLUDE_PRELOAD_LSL_

integer preload_pause = 0;
list preload_sound;
integer preload_sound_i;
list preload_texture;
integer preload_texture_i;
float preload_alpha = 0.0;

void preload_ontime() {
   integer i;
   key uuid;

   //llOwnerSay(llDumpList2String(["preload:", preload_pause, llGetListLength(preload_sound), llGetListLength(preload_texture)], ","));
   if (!preload_pause) {
      i = llGetListLength(preload_sound);
      if (i) {
         if (preload_sound_i >= i) {
            preload_sound_i = 0;
         }
         uuid = (key) llList2String(preload_sound, preload_sound_i);
         llPlaySound(uuid, preload_alpha); // llPreloadSound has a delay, but llPlaySound does not
         preload_sound_i++;
      }

      i = llGetListLength(preload_texture);
      if (i) {
         if (preload_texture_i >= i) {
            preload_texture_i = 0;
         }
         uuid = (key) llList2String(preload_texture, preload_texture_i);
         //llOwnerSay(llDumpList2String(["loading", uuid, preload_alpha], ","));
         llParticleSystem([
               PSYS_SRC_TEXTURE, uuid,
               PSYS_SRC_MAX_AGE, 1.0,
               PSYS_SRC_BURST_RATE, 1.0,
               PSYS_SRC_BURST_PART_COUNT, 1,
               PSYS_PART_START_ALPHA, preload_alpha,
               PSYS_PART_START_SCALE, <4.0,0.1,0.0>
               ]);
         preload_texture_i++;
      }
   }
}

void preload_parse(list pieces) {
   string arg1 = llList2String(pieces, 1);
   string arg2 = llList2String(pieces, 2);
   if (arg1 == "sound") {
      if (arg2 == "clear") {
         preload_sound = [];
      }
      else if (-1 == llListFindList(preload_sound, [ arg2 ])) {
         preload_sound = [ arg2 ] + preload_sound;
         //llDebugSay("added sound '"+arg2+"'");
         //llDebugSay(llDumpList2String(preload_sound, "**"));
      }
   }
   else if (arg1 == "texture") {
      if (arg2 == "clear") {
         preload_texture = [];
      }
      else if (-1 == llListFindList(preload_texture, [ arg2 ])) {
         preload_texture = [ arg2 ] + preload_texture;
      }
   }
   else if (arg1 == "stop") {
      preload_pause = 1;
   }
   else if (arg1 == "start") {
      preload_pause = 0;
   }
   else if (arg1 == "alpha") {
      preload_alpha = (float) arg2;
   }
}

#endif
