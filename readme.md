# Title Check
This addon monitors for interactions with the title changer bard NPCs and records your character's known titles. Recording is done automatically anytime you talk to a bard NPC with the addon loaded, and raw data is saved at `ashita/config/addons/titlecheck/char_id.lua`. You can print a user readable copy to `ashita/config/addons/titlecheck/char_id.txt` by typing `/title dump`. The readable copy will list missing titles, known titles, and if you haven't talked to all 16 bards it will also list which titles have not been verified in one way or the other and the bards that can provide them.

# Updating Bard Files
I've included the method I used to generate the bard data files in the addon, in case it ever needs updates. To update a bard, follow these steps:

1. Type `/tr forcevisible` to turn on a mode that will show all titles as available.
2. Type `/tr reset` to clear any residual data.
3. Talk to the bard, select the first category(often 200 gil), and let the menu load. Type `/tr record 1 200` to indicate it's the first category and costs 200 gil.
4. Exit the menu, talk again, and repeat for the next 5 categories, using the position in menu(1-6) and price.
5. Once you've recorded all 6 categories, exit the menu and target the bard NPC.
6. Type `/tr dump` and the NPC's data will be recorded and immediately ready for use.