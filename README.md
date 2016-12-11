***ios-sticker-packs-app*** a customizable sticker iMessage App with tabbed category switcher.
===================

![Fluffcorn screenshot](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-winter-16.png)

This is the repository for Fluffcorn stickers, an iMessage sticker app. If you want to preview its functionality, download Fluffcorn on the App Store for free [here](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages).

- Notable features
  - Customizable tabbed category switcher.
  - User feedback submission. (Using Google Forms)

How to use for your own stickers
-------------
1. Clone or download ***ios-sticker-packs-app***.
2. Delete all resources in `Art Assets` in Xcode.
3. Add your own sticker images to the project.
4. Edit `stickerPacks.json` to include your own stickers.
5. Edit `about.txt` to include your app information.
6. **If you want Feedback submission**, follow [this](http://stackoverflow.com/questions/12358002/submit-data-to-google-spreadsheet-form-from-objective-c) and edit `sendFeedbackAction:` in `MessagesViewController.h`.
7. **If you do NOT want Feedback submission**, comment out `[infoAlert addAction:sendFeedbackAction];` in `MessagesViewController.h` by inserting `//` at the beginning of the line.
6. Edit App Name, Bundle ID, Version, Build data.
7. Submit to App Store. 

License
-------------
All art assets in this repository (any images including PNG and APNG) are © 2016 Alisha Liu under Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. [![Creative Commons License](https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png "Creative Commons License")](http://creativecommons.org/licenses/by-nc-nd/4.0/)

Everything else (the code and text assets) in this repository are made available under MIT License. 

When using ***ios-sticker-packs-app*** for your own iMessage sticker app, remove all resources in the `Art Assets` file group in the Xcode Navigator to get rid of the Fluffcorn art assets and provide your own art. 