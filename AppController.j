/*
 * AppController.j
 * SlideSync
 *
 * Created by You on May 1, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@import "UBSlideSync/UBSlideView.j"
@import "ICON/ICON.j"

@implementation AppController : CPResponder
{
    @outlet CPWindow    theWindow; 
    ICON icon;
    UBSlideView slideController;
    boolean isController;
}


- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
  // This is called when the application is done loading.
}

- (void)awakeFromCib
{
  // This is called when the cib is done loading.
  // You can implement this method on any object instantiated from a Cib.
  // It's a useful hook for setting up current UI values, and other things.

  // In this case, we want the window from Cib to become our full browser window
  [[theWindow contentView] 
    setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
  [theWindow setFullPlatformWindow:YES];

  icon = [[ICON alloc] initWithServer:"http://mjolnir.cse.buffalo.edu/SlideSync/ICON/ICON.php"
                       login:"anonymous"
                       password:""
                       path:"/slidesync/shows/01-IntroAndModeling"];
  isController = false;
}

- (void)setupSlideshow
{
  slideController = [[UBSlideView alloc] initWithICON:icon];
  [theWindow setInitialFirstResponder:[slideController commandView]];
  [[slideController view] setFrame:[[theWindow contentView] frame]];
      
  [[theWindow contentView] addSubview:[slideController view]];
  [slideController setDelegate:self];
  [icon registerForUpdatesToPath:[self path]+"/slides"
        target:self
        selector:@selector(slidesUpdated:)];
  [icon registerForUpdatesToPath:[self path]+"/activeSlide"
        target:self
        selector:@selector(activeSlideUpdated:)];
}

- (void)slideView:(UBSlideView)view loadedSlide:(int)slide
{
  if(isController){
    [icon writeToPath:[self path]+"/activeSlide"
          data:""+slide];
  }
}

- (void)activeSlideUpdated:(id)newSlide
{
  CPLog("New Slide: %@", newSlide);
}

@end
