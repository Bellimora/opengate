#ifndef _INCLUDE_IS_LOCKED_LSL_
#define _INCLUDE_IS_LOCKED_LSL_

#define is_locked() (!(llGetObjectPermMask(MASK_OWNER) & PERM_MOVE))

#endif
