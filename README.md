**ios-sticker-packs-app**
===================
###A customizable sticker iMessage App with tabbed category switcher and sticker size slider.

[![Fluffcorn screenshot](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-winter-16.png)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages) [![Fluffcorn screenshot sticker size slider visible](https://raw.githubusercontent.com/Fluffcorn/ios-sticker-packs-app/master/images/ios-sticker-size-slider-visible.png)](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages)

- Notable features
  - Customizable tabbed category switcher.
  - User adjustable sticker size slider.
     - Adjustable default sticker size.
  - User feedback submission.
     - Pre-setup with Google Sheets as storage.
  - Persistence for:
     - Last selected category
     - Adjusted sticker size
  - Analytics integration.
     - [Fabric](https://fabric.io/) Crashlytics/Answers enabled.

This code is used in **Fluffcorn stickers**, a iMessage sticker app. If you want to preview its functionality, download Fluffcorn on the App Store for free [HERE](https://itunes.apple.com/us/app/fluffcorn-by-alisha-liu/id1171532447?app=messages). 

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
9. Setup or disable Fabric integration. See [Configuring Fabric Integration](#configuring-fabric-integration)
10. Submit to App Store. 


#### How to edit `stickerPacks.json`

`stickerPacks.json` is in JSON format. 

There are two keys in the root dictionary. 
`packOrder` is an array with order of the "packs" (categories). 
`allPacks` is a dictionary containing keys for each "pack". 
Each pack is a dictionary with a `order` key which is an array containing a dictionary for each sticker in that pack. 
`filename` is the filename of the sticker in your project.
`description` is the accessibility label for the sticker.

#### Configuring Default Sticker Size

- Set `kDefaultStickerSize` in `Constants.h` to `0`,`1`, `2` for `MSStickerSizeSmall`, `MSStickerSizeRegular`,`MSStickerSizeLarge` respectively.
- [`MSStickerSize` reference](https://developer.apple.com/reference/messages/msstickersize?language=objc). 

####Configuring Sticker Size Slider Visibility

- **If you want the sticker size slider to be visible**, set `kStickerSizeSliderVisibility` in `Constants.h` to `YES`.
- **If you want the sticker size slider to NOT be visible**, set `kStickerSizeSliderVisibility` in `Constants.h` to `NO`.

####Configuring Feedback Submission

- **If you want Feedback submission**, set `kFeedbackAction` in `Constants.h` to `YES`.  Follow [this post](http://stackoverflow.com/questions/12358002/submit-data-to-google-spreadsheet-form-from-objective-c) and edit `sendFeedbackAction:` in `MessagesViewController.h` with the appropriate values for your Google Form.
- **If you do NOT want Feedback submission**, set `kFeedbackAction` in `Constants.h` to `NO`. 

####Configuring Fabric Integration

- **If you want Fabric integration**, set `kFabricEnabled` in `Constants.h` to `YES`. 
- Create files named `fabric.apikey` and `fabric.buildsecret` in the `$SRCROOT` directory (usually the project directory). Include your API key and build secret in the files respectively. 
- Add the below lines to your `.gitignore` file if you intend on making the source code public.
```
fabric.apikey
fabric.buildsecret
```
- Verify that *Run Script* located under the *MessagesExtension* > *Build Phases* matches the below bash code.

```
FABRIC_APIKEY=$(cat ${SRCROOT}/fabric.apikey)
FABRIC_BUILDSECRET=$(cat ${SRCROOT}/fabric.buildsecret)
${SRCROOT}/Fabric.framework/run ${FABRIC_APIKEY} ${FABRIC_BUILDSECRET}
```

- **If you do NOT want Fabric integration**, set `kFabricEnabled` in `Constants.h` to `NO`. 
- Remove *Run Script* located under the *MessagesExtension* > *Build Phases*. 
- Remove files `fabric.apikey` and `fabric.buildsecret` from Xcode.


#### Using APNG stickers

There are some non-obvious steps to using animated PNG (APNG) stickers in a iMessage App versus a no-code Sticker app.

- APNG must be under 500kb. Xcode processes images during build time and if your image is under but too close to 500kb, the image will be too big and the Apple sticker browser will not work correctly.
- APNG files must be imported with the `.png` extension. 
- Make sure the imported files have `MessagesExtension` selected for target membership.

#### Removing Existing Art Assets

When using **ios-sticker-packs-app** for your own iMessage sticker app, remove all resources in the `Art Assets` file group in the Xcode Navigator to get rid of the Fluffcorn art assets and provide your own art. 

#### Settings.bundle

Standalone iMessage apps do not currently seem to appear in the Settings app. `Settings.bundle` is included if you would like a Settings menu in an iOS app.

License and Contributing
-------------
All art assets in this repository (any images including PNG and APNG) are © 2016 Alisha Liu under Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. [![Creative Commons License](https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png "Creative Commons License")](http://creativecommons.org/licenses/by-nc-nd/4.0/)

Everything else (the code and text assets) in this repository is made available under MIT License. 

*Visible attribution to ios-sticker-packs-app by [Anson Liu](ansonliu.com), [Alisha Liu](alishaliu.com) required if used publicly or commercially.*

Issues, feature requests, and contributions welcome!
