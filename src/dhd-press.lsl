#include "global.h"
#include "objdesc.lsl"

// set type, pos, rot, size based on four vectors

void presspos(vector v0, vector v1, vector v2, vector v3) {

//   v0   v1
//    +---+
//   /     \
//  +-------+
// v3       v2

   vector centroid = (v0 + v1 + v2 + v3) / 4.0;
   vector midtop = (v0 + v1)/2.0;
   vector midbottom = (v2 + v3)/2.0;

   vector v_up = midtop - centroid;
   vector v_left = (v_up % (v3 - centroid)) % v_up;
   vector v_fwd = v_up % v_left;

   v_up = v_up / llVecMag(v_up);
   v_fwd = v_fwd / llVecMag(v_fwd);
   v_left = v_left / llVecMag(v_left);

   float top = llVecMag(v0 - v1);
   float bottom = llVecMag(v2 - v3);

   float length = llVecMag(midtop - midbottom);

   llSetLinkPrimitiveParamsFast(LINK_THIS, [
         PRIM_TYPE, PRIM_TYPE_BOX, 0, <0, 1, 0>, 0.0, ZERO_VECTOR, <1, top / bottom, 0>, ZERO_VECTOR,
         PRIM_POSITION, centroid, 
         PRIM_ROTATION, llEuler2Rot(<270,0,0> * DEG_TO_RAD) * llAxes2Rot(v_fwd, v_up, v_left),
         PRIM_SIZE, <0.025, bottom, length>
         ]);
}

void bobpos(vector pos, rotation rot, vector scale) {

   llSetLinkPrimitiveParamsFast(LINK_THIS, [
         PRIM_TYPE, PRIM_TYPE_SPHERE, 0, <0, 1, 0>, 0.0, ZERO_VECTOR, <0, 1, 0>,
         PRIM_POSITION, pos, 
         PRIM_ROTATION, rot,
         PRIM_SIZE, scale
         ]);

}

default
{
   state_entry()
   {
      integer channel = (integer) llGetObjectDesc();
      llListen(channel, "", NULL_KEY, "");
   }

   on_rez(integer param) {
      llSetObjectDesc((string) param);
      llResetScript();
   }

   listen(integer unused_channel, string unused_name, key unused_id, string mesg) {
      list l = llParseString2List(mesg, ["|"], []);
      if (llList2String(l,0) == "presspos") {
         presspos(
               (vector) llList2String(l, 1),
               (vector) llList2String(l, 2),
               (vector) llList2String(l, 3),
               (vector) llList2String(l, 4));
      }
      else if (llList2String(l,0) == "bobpos") {
         bobpos(
               (vector) llList2String(l, 1),
               (rotation) llList2String(l, 2),
               (vector) llList2String(l, 3));
      }
      else if (llList2String(l,0) == "detail") {
         llSetLinkPrimitiveParamsFast(LINK_THIS,[
               PRIM_COLOR, ALL_SIDES, (vector) llList2String(l, 1), (float) llList2String(l, 2),
               PRIM_FULLBRIGHT, ALL_SIDES, (integer) llList2String(l, 3),
               PRIM_GLOW, ALL_SIDES, (float) llList2String(l, 4),
               PRIM_TEXTURE, ALL_SIDES, llList2String(l,5), <1,1,0>, ZERO_VECTOR, 0.0
               ]);
         llSetScriptState(llGetScriptName(), 0);
      }
   }
}
