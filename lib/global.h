#define EMAIL_HOST "lsl.secondlife.com"

#define SEP1 "@"
#define SEP2 "|"

#define CHORD_PERIOD_MIN 7
#define CHORD_PERIOD_JITTER 3
#define QUEUE_PERIOD_MIN 3
#define QUEUE_PERIOD_JITTER 3
#define PHONEHOME_PERIOD_MIN (60*10)
#define PHONEHOME_PERIOD_JITTER (60*10)
#define MAIL_PERIOD_MIN 32
#define MAIL_PERIOD_JITTER 32
#define MAILCHECK_PERIOD_MIN 3
#define MAILCHECK_PERIOD_JITTER 7

#define MESG_SEND    0x8370001
#define MESG_RECV    0x8370002

#define RADIONUM 918427

#define llGetListLength(x) \
   (x != [])

#define strreplace(src, from, to) \
   llDumpList2String(llParseStringKeepNulls(src, [from], []), to)

#define url_part(x) \
   unshrink(llList2String(llParseStringKeepNulls((x), [ SEP1 ], []), 1))

#define key_part(x) \
   llList2String(llParseStringKeepNulls((x), [ SEP1 ], []), 0)

#define send(to, elems...) \
   llMessageLinked(LINK_THIS, MESG_SEND, llDumpList2String([elems], "/"), to)

#define sendl(to, elems) \
   llMessageLinked(LINK_THIS, MESG_SEND, llDumpList2String(elems, "/"), to)

#define hash(x) \
   llMD5String(llToLower(x), 0)

#define hasflag(x) \
   (-1 != llSubStringIndex(llGetObjectDesc(), "{"+(x)+"}"))

#define llDebugSay(x) \
   { llSay(DEBUG_CHANNEL, x); llRegionSay(8675, x); }

