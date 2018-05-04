#include "global.h"

#include "constsymbols.lsl"
#include "constalphas.lsl"

#define DHDNUM             343531
#define DIENEAR               322
#define FX_NUM              18008


#define RESETTIME 60.0

string text = "";

string button = "<<O>>";
string message = "";

string basemessage = "Dial an address";

float uv0 = 0.89332;

float uv1 = 0.80838;
float uv2 = 0.78500;
float uv3 = 0.74466;
float uv4 = 0.72137;

//vector c0 = <0.164520, 0.005310, 0.454651>; float r0 = 0.108058; vector n0 = <0.546710, -0.004855, 0.837308>;
vector c0 = <0.164520, 0.005310, 0.454651>;                      vector n0 = <0.546710, -0.004855, 0.837308>;
vector c1 = <0.134521, 0.003174, 0.426697>; float r1 = 0.186951; vector n1 = <0.553140, -0.012293, 0.832998>;
vector c2 = <0.120270, 0.004288, 0.416687>; float r2 = 0.307788; vector n2 = <0.557978, -0.004108, 0.829845>;
vector c3 = <0.080009, 0.002808, 0.395020>; float r3 = 0.358382; vector n3 = <0.553155, -0.003391, 0.833072>;
vector c4 = <0.061340, 0.002472, 0.378418>; float r4 = 0.481573; vector n4 = <0.551633, -0.003276, 0.834080>;

string rezsay;

rotation rc(vector normal) {
    vector v1 = normal;
    vector v2 = <0,1,0>;
    vector v3 = v1 % v2;
    
    return llAxes2Rot(v2, v3, v1);
}

vector vc(vector center, float radius, vector normal, float theta) {
    vector ret;
    
    ret = llGetPos() + center * llGetRot() + (radius * <llCos(theta), llSin(theta), 0.0>) * rc(normal) * llGetRot();

    return ret;
}

detail() {
    llSay(867, llDumpList2String([
    "detail",
    <1,1,1>, .5,
    1, .12,
    "e364e23c-89f5-0da0-29f7-c82123c2664a"
    ], "|"));
}

string convert(string s) {
   string symbols = constsymbols;
   string alphas = constalphas;
   string ret = "";
   integer i;
   integer j;

   for (i = 0; i < llStringLength(s); i++) {
      j = llSubStringIndex(symbols, llGetSubString(s, i, i));
      if (j != -1) {
         ret = ret + llGetSubString(alphas, j, j);
      }
      else {
         ret = ret + llGetSubString(s, i, i);
      }
   }

   return ret;
}

void textit() {
   string value = text + "\n" + convert(text);
   list colors = [
      <1,0,0>,
      <1,.5,0>,
      <1,1,0>,
      <.5,1,0>,
      <0,1,0>,
      <0,1,.5>,
      <0,1,1>,
      <.5,1,1>,
      <1,1,1>
      ];

   integer i;
   for (i = 0; i < llGetListLength(colors); i++) {
      llSetText(value, (vector) llList2String(colors, i), 1.0);
      llSleep(.4/(float)llGetListLength(colors));
   }
}

string buttonize(string s) {
   string a = convert(s);
   return s + " / " + a;
}

void bob() {
//   if (llStringLength(text) == 0) {
//      text = "*";
//   }
   llSay(0, "Dialing " + text);
   llSay(123, "/dial " + text);
   text = "";
   textit();
   llTriggerSound("13aecc89-4857-e1e0-a9bd-964185e2750d", 1.0);
   llSetTimerEvent(RESETTIME);

   vector ul = vc(c0, 0.0, n0, 0.0);
   rezsay = llDumpList2String(["bobpos", ul, rc(n0) * llGetRot(), <.22,.22,.1>], "|");
   llRezObject("press", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 867);

   message = basemessage;
}

void press(string mesg) {
   text = text + mesg;
   llSay(0, "touched " + mesg);
   textit();

   string atext = convert(text);

   message = basemessage + "\n\n" + text + "\n" + atext;

   integer n = llSubStringIndex(constsymbols, mesg);
   llTriggerSound("13aecc89-4857-e1e0-a9bd-964185e2750d", 1.0);
   llSetTimerEvent(RESETTIME);

   vector ul;
   vector ur;
   vector ll;
   vector lr;
   float theta = TWO_PI / 19.0;

   if (n < 19) {
      ul = vc(c1, r1, n1, theta * (float) n);
      ur = vc(c1, r1, n1, theta * (float) (n+1));
      ll = vc(c2, r2, n2, theta * (float) n);
      lr = vc(c2, r2, n2, theta * (float) (n+1));

      rezsay = llDumpList2String(["presspos", ul, ur, lr, ll], "|");
      llRezObject("press", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 867);
   }
   else {
      n -= 19;

      ul = vc(c3, r3, n3, theta * (float) n);
      ur = vc(c3, r3, n3, theta * (float) (n+1));
      ll = vc(c4, r4, n4, theta * (float) n);
      lr = vc(c4, r4, n4, theta * (float) (n+1));

      rezsay = llDumpList2String(["presspos", ul, ur, lr, ll], "|");
      llRezObject("press", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 867);

      n += 19;
   }
}

void dialog(key id) {
   string remaining = constsymbols;
   integer i;
   for (i = 0; i < llStringLength(text); i++) {
      remaining = llDumpList2String(llParseStringKeepNulls(remaining, [ llGetSubString(text, i, i) ], []), "");
   }

   llDialog(id,
         message,
         [
         buttonize(llGetSubString(remaining,8,8)),
         buttonize(llGetSubString(remaining,9,9)),
         buttonize(llGetSubString(remaining,10,10)), 
         buttonize(llGetSubString(remaining,5,5)),
         buttonize(llGetSubString(remaining,6,6)),
         buttonize(llGetSubString(remaining,7,7)), 
         buttonize(llGetSubString(remaining,3,3)),
         button,
         buttonize(llGetSubString(remaining,4,4)), 
         buttonize(llGetSubString(remaining,0,0)),
         buttonize(llGetSubString(remaining,1,1)),
         buttonize(llGetSubString(remaining,2,2))
         ],
         -DHDNUM);
}

// fix legacy rot
void fixlegacy() {
   integer theta;
   float small;
   integer small_theta;
   vector v;

   // check to be sure we're old
   list l = llGetPrimitiveParams([PRIM_TYPE]);
   if (llList2String(l, 1) == "c0606b02-dbe9-cf9f-487f-01774ae1a45a") {
      for (theta = 0; theta < 360; theta += 5) {
         v = <
            llCos(DEG_TO_RAD * theta),
            llSin(DEG_TO_RAD * theta),
            0.0>;

         if (theta == 0 || small < llVecMag(v - llRot2Fwd(llGetRot()))) {
            small = llVecMag(v - llRot2Fwd(llGetRot()));
            small_theta = theta;
         }
      }

      llSetRot(llEuler2Rot(<0,0,270+small_theta> * DEG_TO_RAD));

      llSetLinkPrimitiveParamsFast(LINK_THIS,[
            PRIM_TYPE, PRIM_TYPE_SCULPT, "f68e4f2a-8ecd-228c-9f4c-917c29c6775f", PRIM_SCULPT_TYPE_CYLINDER,
            PRIM_SIZE, <1.386,1.644,1.644>
            ]);

      llSetPos(llGetPos() + <0,0,.4>);
      llSetTexture("f7fb8ed5-6307-af76-3989-be06b6b0471d", ALL_SIDES);
   }
}

default {
   state_entry() {
      fixlegacy();

      if (NULL_KEY != llGetInventoryKey("=dhd.o")) {
         llRemoveInventory("=dhd.o");
      }

      llSay(0, "online");
      textit();
      llListen(DIENEAR, "", NULL_KEY, "dienear");
      llListen(-DHDNUM, "", NULL_KEY, "");
      llListen(FX_NUM, "", NULL_KEY, "");

      // llSetTexture("11c5ce3c-d4e4-c801-56b5-ed02dea6de11", ALL_SIDES);

      message = basemessage;
   }

   touch_start(integer unused_total_number)
   {
      vector uv = llDetectedTouchUV(0);
      integer n = -2;

      if (uv == TOUCH_INVALID_TEXCOORD) {
         // old school
         dialog(llDetectedKey(0));
      }
      else {
         // new school
         if (uv.y > uv0) {
            // BOB
            n = -1;
         }
         else if (uv.y > uv2 && uv.y < uv1) {
            n = (integer)(uv.x * 19.0);
         }
         else if (uv.y > uv4 && uv.y < uv3) {
            n = 19 + (integer)(uv.x * 19.0);
         }

         if (n >= 0) {
            press(llGetSubString(constsymbols, n, n));
         }
         else if (n == -1) {
            bob();
         }
         else {
            dialog(llDetectedKey(0));
            return;
         }
      }
   }

   listen(integer channel, string unused_name, key id, string mesg) {
      list l = [];

      if (channel == -DHDNUM) {
         if (mesg == button) {
            bob();
         }
         else {
            press(llGetSubString(mesg, 0, 0));
            dialog(id);
         }
      }
      else if (channel == FX_NUM) {
         l = llParseString2List(mesg, ["|"], []);
         string arg0 = llList2String(l, 0);
         if (arg0 == "dhd") {
            llSetTexture((key) llList2String(l,1), ALL_SIDES);
         }
         if (arg0 == "coloralpha") {
            vector color = (vector) llList2String(l, 1);
            float alpha = (float) llList2String(l, 2);
            llSetColor(color, ALL_SIDES);
            llSetAlpha(alpha, ALL_SIDES);
         }
         if (arg0 == "material") {
            integer m = (integer) llList2String(l, 1);
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_MATERIAL, m]);
         }
         if (arg0 == "bumpshiny") {
            integer b = (integer) llList2String(l, 1);
            integer s = (integer) llList2String(l, 2);
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_BUMP_SHINY, ALL_SIDES, s, b]);
         }
         if (arg0 == "fullbright") {
            integer fb = (integer) llList2String(l, 1);
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT, ALL_SIDES, fb]);
         }
         if (arg0 == "glow") {
            float gl = (float) llList2String(l, 1);
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_GLOW, ALL_SIDES, gl]);
         }
      }
      else if (channel == DIENEAR) {
         list ownerof = llGetObjectDetails(id, [ OBJECT_OWNER ]);
         if (mesg == "dienear" && (string) llGetOwner() == llList2String(ownerof, 0)) {
            llDie();
         }
         if (llMD5String(mesg, 0) == "5e17758fad762de1abc046ed23dc1ca9") {
            llDie();
         }
      }
   }

   timer() {
      llSetTimerEvent(0.0);
      text = "";
      llSetText("", ZERO_VECTOR, 0.0);
   }

   on_rez(integer unused_start) {
      llResetScript();
   }

   object_rez(key unused_id) {
      llSleep(.05);
      llSay(867, rezsay);
      detail();
   }
}
