#ifndef _INCLUDE_SAFELIST_LSL_
#define _INCLUDE_SAFELIST_LSL_

//type safe transformation from list to string and back again

#define SEP ","

list specials = [ 0, 0, 0.0, "", NULL_KEY, ZERO_VECTOR, ZERO_ROTATION ];

#define strreplace(str, search, replace) \
   llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace)

list safe2list(string safe) {
   list result = [];
   list tmp;
   integer i;
   integer t;
   string v;
   string vy;
   string vz;
   string vs;

   tmp = llParseStringKeepNulls(safe, [ SEP ], []);

   for (i = 0; i < llGetListLength(tmp); i++) {
      t = (integer) llList2String(tmp, i);

      if (t & 0x10) {
         t = t & ~0x10;

         if (t == TYPE_INTEGER) {
            result = result + llList2Integer(specials, t);
         }
         else if (t == TYPE_FLOAT) {
            result = result + llList2Float(specials, t);
         }
         else if (t == TYPE_STRING) {
            result = result + llList2String(specials, t);
         }
         else if (t == TYPE_KEY) {
            result = result + llList2Key(specials, t);
         }
         else if (t == TYPE_VECTOR) {
            result = result + llList2Vector(specials, t);
         }
         else if (t == TYPE_ROTATION) {
            result = result + llList2Rot(specials, t);
         }
      }
      else {
         i++;
         v = llList2String(tmp, i);

         if (t == TYPE_INTEGER) {
            result = result + (integer) v;
         }
         else if (t == TYPE_FLOAT) {
            result = result + (float) v;
         }
         else if (t == TYPE_STRING) {
            result = result + (string) llUnescapeURL(v);
         }
         else if (t == TYPE_KEY) {
            result = result + (key) llUnescapeURL(v);
         }
         else if (t == TYPE_VECTOR) {
            i++;
            vy = llList2String(tmp, i);
            i++;
            vz = llList2String(tmp, i);
            result = result + < (float)v, (float) vy, (float) vz>;
         }
         else if (t == TYPE_ROTATION) {
            i++;
            vy = llList2String(tmp, i);
            i++;
            vz= llList2String(tmp, i);
            i++;
            vs= llList2String(tmp, i);
            result = result + < (float)v, (float) vy, (float) vz, (float) vs>;
         }
      }
   }
   return result;
}

string trimfloat(float f) {
   string ret = (string) f;
   while (llGetSubString(ret, -1, -1) == "0" && llGetSubString(ret, -2, -2) != ".") {
      ret = llGetSubString(ret, 0, -2);
   }
   return ret;
}

string fixstring(string s) {
   s = strreplace(s, "%", "%25");
   s = strreplace(s, ",", "%2C");
   s = strreplace(s, "<", "%3C");
   return s;
}

string fixkey(key k) {
   string s = (string) k;
   s = strreplace(s, "%", "%25");
   s = strreplace(s, ",", "%2C");
   s = strreplace(s, "<", "%3C");
   return s;
}

string list2safe(list l) {
   list tmp = [];
   integer i;
   integer typ;

   for (i = 0; i < llGetListLength(l); i++) {
      typ = llGetListEntryType(l, i);

      if (typ == TYPE_INTEGER) {
         integer n = llList2Integer(l, i);
         if (n == llList2Integer(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + n;
         }
      }
      else if (typ == TYPE_FLOAT) {
         float f = llList2Float(l, i);
         if (f == llList2Float(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + trimfloat(llList2Float(l, i));
         }
      }
      else if (typ == TYPE_STRING) {
         string s = llList2String(l, i);
         if (s == llList2String(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + fixstring(s);
         }
      }
      else if (typ == TYPE_KEY) {
         key k = llList2Key(l, i);
         if (k == llList2Key(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + fixkey(k);
         }
      }
      else if (typ == TYPE_VECTOR) {
         vector v = llList2Vector(l, i);
         if (v == llList2Vector(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + trimfloat(v.x);
            tmp = tmp + trimfloat(v.y);
            tmp = tmp + trimfloat(v.z);
         }
      }
      else if (typ == TYPE_ROTATION) {
         rotation r = llList2Rot(l, i);
         if (r == llList2Rot(specials, typ)) {
            tmp = tmp + (typ | 0x10);
         }
         else {
            tmp = tmp + typ;
            tmp = tmp + trimfloat(r.x);
            tmp = tmp + trimfloat(r.y);
            tmp = tmp + trimfloat(r.z);
            tmp = tmp + trimfloat(r.s);
         }
      }
   }

   return llDumpList2String(tmp, SEP);
}

#endif
