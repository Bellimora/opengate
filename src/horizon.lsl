#include "objdesc.lsl"
list where = ["", ZERO_VECTOR, ZERO_ROTATION];
list splashers = [];

vector global_coords;
integer rlv_reqid;

integer handle;

integer whispered = 0;

key horizon_texture;
string horizon_animation;
key particle_texture;
key woosh_sound;
key splash_sound;
key loop_sound;
key theme_hsoow_sound;
key theme_collapse;
string shape;

//float time = .750;

integer s = 0;

void out () {
   llParticleSystem([
         PSYS_PART_FLAGS, PSYS_PART_TARGET_POS_MASK | PSYS_PART_EMISSIVE_MASK,
         PSYS_SRC_PATTERN, 2, 
         PSYS_PART_START_ALPHA, 0.2,
         PSYS_PART_END_ALPHA, 0.0,
         PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
         PSYS_PART_END_COLOR, <1.0, 1.0, 1.0>,
         PSYS_PART_START_SCALE, <3.0, 3.0, 0.0>,
         PSYS_PART_END_SCALE, <1.25, 1.25, 0.0>,
         PSYS_PART_MAX_AGE, 2.0,
         PSYS_SRC_MAX_AGE, 2.0,
         PSYS_SRC_ACCEL, <0.0, 0.0, 35.0>*llGetRot(),
         PSYS_SRC_ANGLE_BEGIN, 0.0,
         PSYS_SRC_ANGLE_END, 0.0,
         PSYS_SRC_BURST_PART_COUNT, 10,
         PSYS_SRC_BURST_RATE, 0.0,
         PSYS_SRC_BURST_RADIUS, 0.0,
         PSYS_SRC_BURST_SPEED_MIN, 5.0,
         PSYS_SRC_BURST_SPEED_MAX, 6.0,
         PSYS_SRC_OMEGA, <0.0, 0.0, 0.0>,
         PSYS_SRC_TARGET_KEY,llGetKey(), 
         PSYS_SRC_TEXTURE, particle_texture ]); //"3124ac03-baac-e08e-cded-063fade39e21"]);
}

void collapse() {
   vector end_color = llGetColor(ALL_SIDES);
   vector start_color = <0,0,end_color.z>;

   float angle_begin = PI / 2.0 + .01;
   float angle_end = PI / 2.0 - .01;

   list particle_parameters = [
      PSYS_SRC_TEXTURE, theme_collapse,
      PSYS_PART_START_SCALE, <0.5, 0.5, FALSE>,
      PSYS_PART_END_SCALE, <2.0, 2.0, FALSE>,
      PSYS_PART_START_COLOR, start_color,
      PSYS_PART_END_COLOR, end_color,
      PSYS_PART_START_ALPHA,  0.8,
      PSYS_PART_END_ALPHA, 0.8,
      PSYS_SRC_BURST_PART_COUNT, 250,
      PSYS_SRC_BURST_RATE, 0.01,
      PSYS_PART_MAX_AGE, 2.2,
      PSYS_SRC_MAX_AGE, 3.0,
      PSYS_SRC_PATTERN, 8,
      PSYS_SRC_BURST_SPEED_MIN, 0.5,
      PSYS_SRC_BURST_SPEED_MAX, 1.0,
      PSYS_SRC_ANGLE_BEGIN, angle_begin,
      PSYS_SRC_ANGLE_END, angle_end,
      PSYS_SRC_ACCEL, <0.0,0.0, 0.0 >,
      PSYS_SRC_BURST_RADIUS, 0.0,
      PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_EMISSIVE_MASK
         ];

   llParticleSystem(particle_parameters);

   llTriggerSound(theme_hsoow_sound, 1.0);
}

void init() {
   float delay;
   list l = llParseString2List(horizon_animation, [ " " ], []);

   if (shape == "hollowsphere") {
      llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_DEFAULT, <0,1,0>, .99, <0,0,0>, <0,1,0> ]  );

      llSetTextureAnim(ANIM_ON |  SMOOTH | ROTATE | LOOP,
            ALL_SIDES, (integer)llList2String(l,0), (integer)llList2String(l,1),
            (float)llList2String(l,2), (float)llList2String(l,3), (float)llList2String(l,4));
   }
   else {
      llSetTextureAnim(ANIM_ON | LOOP, ALL_SIDES, (integer)llList2String(l,0), (integer)llList2String(l,1),
            (float)llList2String(l,2), (float)llList2String(l,3), (float)llList2String(l,4));
   }

   llSetColor(<1,1,1>, ALL_SIDES);
   llSetAlpha(1.0, ALL_SIDES);
   llSleep(.05);
   llTriggerSound(woosh_sound, 1.0);
   llSetTexture(horizon_texture, ALL_SIDES);
   llLoopSound(loop_sound, 1.0);

   if (shape == "hollowsphere") {
      llSetAlpha(.55,0);
   }
   else {
      llSetAlpha(.55,2);
   }

   out();

   delay = 2.0 - llGetTime();
   if (delay <= 0.0) {
      delay = 0.01;
   }
   llSetTimerEvent(delay);

   llTargetOmega(ZERO_VECTOR, 0.0, 0.0);
}

default
{
   state_entry() {
      if (llGetObjectDesc() != "0") {
         llSetObjectName("Event Horizon");
         handle = llListen((integer) llGetObjectDesc(), "", "", "");
      }
      else {
         llParticleSystem([]);
         llSetTexture("f54a0c32-3cd1-d49a-5b4f-7b792bebc204", ALL_SIDES);
      }
   }

   collision_start(integer num) {
      integer i;
      if (splash_sound != NULL_KEY) {
         for (i = 0; i < num; i++) {
            if (-1 == llListFindList(splashers, [ llDetectedKey(i) ])) {
               llTriggerSound(splash_sound, 1.0);
               splashers = splashers + llDetectedKey(i);
            }
         }
      }
      if (llStringLength(llList2String(where,0)) == 0) {
         return;
      }
      if (!whispered) {
         whispered = 1;
         llWhisper(0, "touch the event horizon to teleport");
      }
      for (i = 0; i < num; i++) {
         llSay(-900000,
               llDumpList2String(["map",
                  llDetectedKey(i),
                  llList2String(where,0),
                  llList2String(where,1),
                  llList2String(where,2)], "|"));
         llSay(-1812221819, llDumpList2String([
                  rlv_reqid++, llDetectedKey(i), "@tpto:"+
                  (string)global_coords.x+"/"+
                  (string)global_coords.y+"/"+
                  (string)global_coords.z+"=force"
                  ]
                  , ","));
      }
   }

   on_rez(integer param) {
      llSetObjectDesc((string) param);
      llResetScript();
   }

   touch_start(integer unused_total_number) {
      if (llStringLength(llList2String(where, 0)) != 0) {
         vector pos = (vector)llList2String(where,1);
         rotation rot = (rotation)llList2String(where,2);
         vector look = pos + llRot2Up(rot);
         llMapDestination(llList2String(where, 0), pos, look);
         // do it twice; workaround for SL Client bug
         llMapDestination(llList2String(where, 0), pos, look);
      }
   }

   dataserver(key unused_reqid, string data) {
      global_coords = (vector) data;
      global_coords += (vector) llList2String(where, 1);
   }

   listen(integer unused_channel, string unused_name, key unused_id, string message) {
      llListenRemove(handle);

      message = llUnescapeURL(message);
      where = llCSV2List(message);

      if (llStringLength(llList2String(where, 0))) {
         llRequestSimulatorData (llList2String(where, 0), DATA_SIM_POS);
      }
      else {
         global_coords = ZERO_VECTOR;
      }

      vector v = (vector) llList2String(where, 3);
      v.x = v.x * 5.75 / 6.0;
      v.y = v.y * 5.75 / 6.0;
      v.z = 0.01;

      horizon_texture = (key) llList2String(where, 4);
      particle_texture = (key) llList2String(where, 5);
      woosh_sound = (key) llList2String(where, 6);
      splash_sound = (key) llList2String(where, 7);
      loop_sound = (key) llList2String(where, 8);
      theme_hsoow_sound = (key) llList2String(where, 9);
      theme_collapse = (key) llList2String(where, 10);
      horizon_animation = llList2String(where,11);
      shape = llList2String(where, 12);

      // don't resize for megaprims like the supergate.
      // resizing there would clamp us at 10x10x10
      if (v.x <= 10.0 && v.y <= 10.0 && v.z <= 10.0) {
         llSetScale(v);
      }

      init();

      llVolumeDetect(TRUE);
   }

   timer() {
      float delay;

      s++;
      if (s == 1) {
         llParticleSystem([]);
         delay = 57.0 - llGetTime();
         llSetTimerEvent(delay);
      }
      else if (s == 2) {
         collapse();
         delay = 59.0 - llGetTime();
         llSetTimerEvent(delay);
      }
      else {
         llSetTexture("f54a0c32-3cd1-d49a-5b4f-7b792bebc204", ALL_SIDES);
      }
   }
}
