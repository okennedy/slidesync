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

  var args = [[CPApplication sharedApplication] arguments];
  var show = "01-IntroAndModeling";
  isController = false;

  if([args count] > 0){ 
    show = [[args objectAtIndex:0] stringByReplacingOccurrencesOfString:"/"
                                   withString:""];
  } else {
    window.location.href = window.location.href+"#"+show;
  }
  if([args count] > 1){ 
    var i;
    for(i = 1; i < [args count]; i++){
      var arg = [args objectAtIndex:i];
      if([arg isEqualToString:"admin"]){
        CPLog("This site is a controller");
        isController = true;
      }
    }
  }

  icon = [[ICON alloc] initWithServer:"ICON/ICON.php"
                       login:"admin"
                       password:"cookie"
                       path:"slidesync/shows/"+show];
  [icon setDelegate:self];
}

- (void)ICONLoginSuccess:(ICON)source
{
  [self setupSlideshow];
}

- (void)setupSlideshow
{
  slideController = [[UBSlideView alloc] init];
  [theWindow setInitialFirstResponder:[slideController commandView]];
  [[slideController view] setFrame:[[theWindow contentView] frame]];
      
  [[theWindow contentView] addSubview:[slideController view]];
  [slideController setDelegate:self];
 
  [icon registerForUpdatesToPath:[icon path]+"/slides"
        target:self
        selector:@selector(slidesUpdated:)];
  [icon registerForUpdatesToPath:[icon path]+"/activeSlide"
        target:self
        selector:@selector(activeSlideUpdated:)];
}

- (void)slideView:(UBSlideView)view loadedSlide:(int)slide
{
  if(isController){
    CPLog("Updating global view to slide %d", slide);
    [icon writeToPath:[icon path]+"/activeSlide"
          data:""+slide];
  } else {
    CPLog("Stepped to slide: %d", slide);
  }
}

- (void)slidesUpdated:(id)newSlidesURL
{
  CPLog("New Slide Path: %@", newSlidesURL);
  [slideController loadContent:newSlidesURL];
}

- (void)activeSlideUpdated:(id)newSlide
{
  if(!isController){
    CPLog("New Slide: %@", newSlide);
    [slideController loadSlide:newSlide*1];
  }
}

@end
