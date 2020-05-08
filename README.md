**ios-sticker-packs-app**
===================
### A customizable sticker iMessage App with tabbed category switcher, sticker size slider, and WhatsApp sticker integration.

[![AppStore](https://img.shields.io/badge/App%20Store-v1.4.1-0d96f6?style=flat&logo=app-store)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages)
[![WhatsApp badge](https://img.shields.io/badge/WhatsApp%20Sticker-✓-25D366?style=flat&logo=whatsapp)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages)
[![Telegram badge](https://img.shields.io/badge/Telegram%20Sticker-✓-2CA5E0?style=flat&logo=telegram)](https://telegram.me/addstickers/FluffcornStickers)
[![Facebook badge](https://img.shields.io/badge/-Follow_on_Facebook-white?style=flat&logo=facebook&labelColor=ffffff&color=1877F2)](https://facebook.com/fluffcorn)
[![Code License badge](https://img.shields.io/badge/code_license-MIT-green?style=flat)](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/LICENSE.txt)
[![Art License badge](https://img.shields.io/badge/art_license-CC_BY--NC--ND_4.0-green?style=flat)](https://creativecommons.org/licenses/by-nc-nd/4.0/)



[![Fluffcorn screenshot](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-winter-16.png)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages) [![Fluffcorn screenshot sticker size slider visible](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-sticker-size-slider-visible.png)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages) [![Fluffcorn WhatsApp Stickers integration](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-whatsapp-stickers-integration.jpeg)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages)

- Features
  - Customizable tabbed category switcher.
  - User adjustable sticker size slider.
     - Adjustable default sticker size.
  - User feedback submission.
     - Pre-setup with Google Sheets as storage.
  - Persistence for:
     - Last selected category
     - Adjusted sticker size
   - [WhatsApp Stickers (WAStickers)](https://github.com/WhatsApp/stickers) installation for each sticker category.
  - Analytics integration.
     - [Firebase](https://firebase.google.com/) Crashlytics/Analytics/Performance enabled.

This code is used in **Fluffcorn stickers**, a iMessage sticker app. If you want to preview its functionality, download Fluffcorn on the App Store for free [HERE](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages). Fluffcorn Stickers are also available on Telegram [here](https://telegram.me/addstickers/FluffcornStickers).

How to use for your own stickers
-------------
1. Clone or download ***ios-sticker-packs-app***.
2. Delete all resources in `Art Assets` in Xcode. See [Removing Existing Art Assets](#removing-existing-art-assets).
3. Add your own sticker images to the project.
4. Edit `stickerPacks.json` to include your own stickers. See [How to edit `stickerPacks.json`](#how-to-use-for-your-own-stickers).
5. Set default sticker size. See [Configuring Default Sticker Size](#configuring-default-sticker-size).
6. Set the sticker size slider visibility. See [Configuring Sticker Size Slider Visibility](#configuring-sticker-size-slider-visibility).
7. Edit `about.txt` to include your app information.
8. Edit App Name, Bundle ID, Version, Build data.
9. Setup or disable Firebase integration. See [Configuring Firebase Integration](#configuring-firebase-analytics-integration)
10. Submit to [App Store](https://developer.apple.com/ios/submit/). 


### How to edit `stickerPacks.json`

`stickerPacks.json` is in JSON format. 

There are two keys in the root dictionary. 
- `packOrder` is an array with order of the "packs" (categories). 
- `allPacks` is a dictionary containing keys for each "pack". 
  - Each pack is a dictionary with two keys, `filename` and `order`.
  - `filename` key for a pack specifies the category "tray" icon (currently only used for WhatsApp Stickers).
  - `order` key is an array containing a dictionary for each sticker in that pack. 
    - `filename` is the filename of the sticker in your project.
    - `description` is the accessibility label for the sticker for human reference. The actual localized text that is used is located in `Localizable.strings`. The `description` value and localized English string in `Localizable.strings` should be kept the identical consistency.
    - `emoji` is an array of up to 3 unicode strings of length 1 containing related emojis. (Only used for WhatsApp Stickers).

All images used for WhatsApp needs add a prefix of `wa_` to the filename. A listed filename of `category1_tray_icon` will use the file named `wa_category1_tray_icon.png` for any WhatsApp Sticker needs.

### Configuring Default Sticker Size

- Set `kDefaultStickerSize` in `Constants.h` to `0`,`1`, `2` for `MSStickerSizeSmall`, `MSStickerSizeRegular`,`MSStickerSizeLarge` respectively.
- [`MSStickerSize` reference](https://developer.apple.com/reference/messages/msstickersize?language=objc). 

| Sticker Size| Points | @3x Pixels (the image size you want to use) | DPI | Max Size |
| --- | --- | --- | --- | -- |
| MSStickerSizeSmall | 100 x 100 | 300 x 300 | 72 | N/A |
| MSStickerSizeRegular | 136 x 136 | 408 x 408 | 72 | N/A |
| MSStickerSizeLarge | 206 x 206 | 618 x 618 | 72 | N/A |
| WhatsApp Sticker Pack Tray Icon | N/A | 96 x 96 | 72 | N/A |
| WhatsApp Sticker | N/A | 512 x 512 | 72 | 100kb |

You should use the listed image size if you intend to display a single sticker size or else stickers may encounter size issues when used in messages. 

Batch image resizing (Photoshop) and compression (`pngcrush`) scripts are in [`miscellaneous`](https://github.com/Fluffcorn/ios-sticker-packs-app/tree/master/miscellaneous) directory. 

### Configuring Sticker Size Slider Visibility

- **If you want the sticker size slider to be visible**, set `kStickerSizeSliderVisibility` in `Constants.h` to `YES`.
- **If you want the sticker size slider to NOT be visible**, set `kStickerSizeSliderVisibility` in `Constants.h` to `NO`.

### Configuring Feedback Submission

- **If you want Feedback submission**, set `kFeedbackAction` in `Constants.h` to `YES`.  Follow [this post](http://stackoverflow.com/questions/12358002/submit-data-to-google-spreadsheet-form-from-objective-c) and edit `sendFeedbackAction:` in `MessagesViewController.h` with the appropriate values for your Google Form.
- **If you do NOT want Feedback submission**, set `kFeedbackAction` in `Constants.h` to `NO`. 

### Configuring Firebase Analytics Integration

- Add your application's `GoogleService-Info.plist to the project.

***Fabric Integration has been deprecated and replaced with Firebase Analytics & Performance Integration. The recommended way to keep your Firebase API key private in a public repository is to add `GoogleService-Info.plist` to the `.gitignore` file.***

- **If you do NOT want Firebase integration**, set `kFirebaseEnabled` in `Constants.h` to `NO`. 
  - Remove *Firebase resources* and *Firebase frameworks*.

### WhatsApp Stickers Integration

See *How to edit `stickerPacks.json`* and *Configuring Default Sticker Size* sections above for WhatsApp Sticker asset information. 

### Using APNG stickers

There are some non-obvious steps to using animated PNG (APNG) stickers in a iMessage App versus a no-code Sticker app.

- APNG must be under 500kb. Xcode processes images during build time and if your image is under but too close to 500kb, the image will be too big and the Apple sticker browser will not work correctly.
- APNG files must be imported with the `.png` extension. 
- Make sure the imported files have `MessagesExtension` selected for target membership.

### Removing Existing Art Assets

When using **ios-sticker-packs-app** for your own iMessage sticker app, remove all resources in the `Art Assets` file group in the Xcode Navigator to get rid of the Fluffcorn art assets and provide your own art. 

### Settings.bundle

Standalone iMessage apps do not currently seem to appear in the Settings app. `Settings.bundle` is included if you would like a Settings menu in an iOS app. The bundle in this project comes with support for adjusting sticker size. 

License and Contributing
-------------
All art assets in this repository (any Fluffcorn images including PNG and APNG) are © 2016 Alisha Liu under Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. [![Creative Commons License](https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png "Creative Commons License")](http://creativecommons.org/licenses/by-nc-nd/4.0/)

All third party code used by Fluffcorn is copyright of their rightful owners.

All original code and text assets in this repository are made available under MIT License. 

*Visible attribution to [Fluffcorn/ios-sticker-packs-app](https://github.com/Fluffcorn/ios-sticker-packs-app) by [Anson Liu](http://ansonliu.com) and [Alisha Liu](http://alishaliu.com) required if code, text, or art are used in any way in a public or commercial product.*

Issues, feature requests, and contributions welcome! All contributions will be placed under MIT License. 
