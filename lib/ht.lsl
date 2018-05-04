#ifndef _INCLUDE_HT_LSL_
#define _INCLUDE_HT_LSL_

#define HT_DECLARE(x) \
   list x ## _keys; \
   list x ## _vals; \
   \
   integer x ## _haskey(string k) { \
      integer i = llListFindList(x ## _keys, [ k ]); \
      if (i == -1) { \
         return 0; \
      } \
      return 1; \
   } \
   \
   void x ## _set(string k, string v) { \
      integer i = llListFindList(x ## _keys, [ k ]); \
      if (i != -1) { \
         x ## _vals = llListReplaceList(x ## _vals, [ v ], i, i); \
      } \
      else { \
         x ## _keys = x ## _keys + k; \
         x ## _vals = x ## _vals + v; \
      } \
   } \
   \
   string x ## _get(string k) { \
      integer i = llListFindList(x ## _keys, [ k ]); \
      if (i != -1) { \
         return llList2String(x ## _vals, i); \
      } \
      return ""; \
   } \
   \
   void x ## _delete(string k) { \
      integer i = llListFindList(x ## _keys, [ k ]); \
      if (i != -1) { \
         x ## _keys = llDeleteSubList(x ## _keys, i, i); \
         x ## _vals = llDeleteSubList(x ## _vals, i, i); \
      } \
   }

#define HT_HASKEY(x, k) x ## _haskey(k)
#define HT_SET(x, k, v) x ## _set(k, v)
#define HT_GET(x, k) x ## _get(k)
#define HT_DELETE(x, k) x ## _delete(k)
#define HT_KEYS(x) x ## _keys
#define HT_VALS(x) x ## _vals

#define HT_ITERATE(x, func, data) \
   { \
      integer _i; \
      list _keys_copy = x ## _keys; \
      integer _max = llGetListLength(_keys_copy); \
      string _k; \
      string _v; \
      integer _done = 0; \
      for (_i = 0; _i < _max && !_done; _i++) { \
         _k = llList2String(_keys_copy, _i); \
         _v = HT_GET(x, _k); \
         _done = func(_k, _v, data); \
      } \
   } 

#endif
