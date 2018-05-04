#ifndef _INCLUDE_FLIP_LSL
#define _INCLUDE_FLIP_LSL

void flip() {
   list l;
   list l2;
   integer i;
   vector vo;
   vector vn;
   rotation ro;
   rotation rn;

   for (i = 1; i <llGetNumberOfPrims(); i++){
      l = llGetLinkPrimitiveParams(i+1, [ PRIM_ROT_LOCAL, PRIM_POS_LOCAL]);

      ro = llList2Rot(l, 0);
      vo = llList2Vector(l, 1);

      // there's a bit of voodoo here...

      rn = <-ro.z, -ro.s, ro.x, ro.y>;
      vn = <-vo.x, vo.y, -vo.z>;

      llSetLinkPrimitiveParamsFast(i+1, [ PRIM_ROT_LOCAL, rn, PRIM_POS_LOCAL, vn ]);
   }
   llSetRot(llGetRot() * llEuler2Rot(<0,0,180> * DEG_TO_RAD));

   l = llGetLinkPrimitiveParams(1, [ PRIM_TYPE ]);

   if (llList2Integer(l, 0) == PRIM_TYPE_CYLINDER) {
      l = llGetLinkPrimitiveParams(1, [ PRIM_TEXTURE, 0 ]);
      l2 = llGetLinkPrimitiveParams(1, [ PRIM_TEXTURE, 3 ]);

      l = llListReplaceList(l, [ llList2Float(l, 3) + PI ], 3, 3);
      l2 = llListReplaceList(l2, [ llList2Float(l2, 3) + PI ], 3, 3);

      llSetLinkPrimitiveParamsFast(1, [ PRIM_TEXTURE, 0 ] + l2);
      llSetLinkPrimitiveParamsFast(1, [ PRIM_TEXTURE, 3 ] + l);
   }
}

void doflip() {
   list l;
   rotation r;
   l = llGetLinkPrimitiveParams(2, [ PRIM_ROT_LOCAL ]);
   r = llList2Rot(l, 0);
#ifdef PHYS_GENERIC
   if (r.x < 0.0) {
#endif
#ifdef PHYS_DESTINY
   if (r.s < 0.5) {
#endif
      flip();
   }
}

#endif
