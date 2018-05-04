#ifndef _INCLUDE_GODS_LSL_
#define _INCLUDE_GODS_LSL_

#define DORAN_ZEMLJA       "5f0c45b4-e8d7-49ae-973f-4c2bb209e852"
#define FEMININE_WILES     "57907029-293c-403d-a785-a7bcdf329d6c"
#define MOOBEE_HOOBINOO    "2334c510-c9fa-4018-9e9b-a08ec1b62a13"
#define ONECUP_HALFPINT    "d56fc3b5-4669-4a03-90fd-73fb1253370a"
#define ADAM_WOZNIAK       "7271eff8-fc0f-47bb-a153-144729f3cef2"
#define OPENGATE_MESSENGER "21958924-d3b4-4183-a858-d75425dc09b9"

list gods = [ DORAN_ZEMLJA,
     FEMININE_WILES,
     MOOBEE_HOOBINOO,
     ONECUP_HALFPINT,
     ADAM_WOZNIAK,
     OPENGATE_MESSENGER // (last!)
     ];

#define isgod(k) (-1 != llListFindList(gods, [ (string) k ]))
#define isadmin(k) (-1 != llListFindList(gods + (string) llGetOwner(), [ (string) k ]))

#endif
