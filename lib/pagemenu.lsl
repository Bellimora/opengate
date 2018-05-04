#ifndef _INCLUDE_PAGEMENU_LSL_
#define _INCLUDE_PAGEMENU_LSL_

#define MAX_DIALOG_CHOICES_PER_PG 9

string PREV_PAGE = "<<";
string NEXT_PAGE = ">>";
integer pageNum = 0;

void Page_Menu(key ID, integer channel_dialog, integer pageDelta, string menu_message, list DIALOG_CHOICES) {
   integer N_DIALOG_CHOICES;
   list buttons;

   integer firstChoice;
   integer nPages;

   N_DIALOG_CHOICES = llGetListLength(DIALOG_CHOICES);

   while (N_DIALOG_CHOICES < 12 || N_DIALOG_CHOICES % 3 != 0) {
      DIALOG_CHOICES += [ "-" ];
      N_DIALOG_CHOICES++;
   }

   if (N_DIALOG_CHOICES <= 12) {
      buttons =
         (buttons=[])+
         llList2List(DIALOG_CHOICES, 9, 11) + llList2List(DIALOG_CHOICES, 6, 8) +
         llList2List(DIALOG_CHOICES, 3, 5) + llList2List(DIALOG_CHOICES, 0, 2) ;
   }
   else {
      nPages = (N_DIALOG_CHOICES + MAX_DIALOG_CHOICES_PER_PG - 1) / MAX_DIALOG_CHOICES_PER_PG;

      pageNum = (pageNum + nPages + pageDelta) % nPages;

      firstChoice = pageNum * MAX_DIALOG_CHOICES_PER_PG;

      buttons =
         (buttons=[])+
         [ PREV_PAGE, "-", NEXT_PAGE ] +
         llList2List(DIALOG_CHOICES, firstChoice + 6, firstChoice + 8) +
         llList2List(DIALOG_CHOICES, firstChoice + 3, firstChoice + 5) +
         llList2List(DIALOG_CHOICES, firstChoice + 0, firstChoice + 2);
   }
   llDialog(ID, menu_message, buttons, channel_dialog);
}

#endif
