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

ICON_SERVER = "ICON/ICON.php";

@implementation AppController : CPResponder
{
  @outlet CPWindow    theWindow; 
  @outlet CPPanel     loginWindow;
  @outlet CPTextField loginUsername; 
  @outlet CPTextField loginPassword;
  @outlet CPTextField loginStatus;
  @outlet CPMenuItem  loginMenuItem;
  ICON icon;
  UBSlideView slideController;
  BOOL isController;
  BOOL wantsController;
}

- (CPString)showPath
{
  var show = "001";
  var args = [[CPApplication sharedApplication] arguments];

  if([args count] > 0){ 
    show = [[args objectAtIndex:0] stringByReplacingOccurrencesOfString:"/"
                                   withString:""];
  } else {
    window.location.href = window.location.href+"#"+show;
  }
  return "slidesync/sessions/"+show;
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

  isController = false;
  wantsController = false;

  icon = [[ICON alloc] initWithServer:ICON_SERVER
                       login:"anonymous"
                       password:""
                       path:[self showPath]];
  [icon setDelegate:self];
  [self setupSlideshow];
}

- (void)ICONLoginSuccess:(ICON)source
{
  CPLog("Login Successful");
  if(wantsController){
    [theWindow setInitialFirstResponder:[slideController commandView]];
    [self endLogin:self];
    [loginMenuItem setEnabled:NO];
    isController = true;
  }
}
- (void)ICONConnectionFailed:(ICON)source reason:(CPString)reason
{
  CPLog("Login Failure");
  if(wantsController){
    [loginStatus setStringValue:"Login Failed: "+reason];
  }
}

- (void)setupSlideshow
{
  slideController = [[UBSlideView alloc] init];
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
  if(newSlidesURL != null){
    CPLog("New Slide Path: %@", newSlidesURL);
    [slideController loadContent:newSlidesURL];
  }
}

- (void)activeSlideUpdated:(id)newSlide
{
  if(newSlide != null){
    if(!isController){
      CPLog("New Slide: %@", newSlide);
      [slideController loadSlide:newSlide*1];
    }
  }
}

- (BOOL)slideViewShouldRespondToMouse:(id)sender
{
  return isController;
}

- (IBAction)loginAsAdmin:(id)sender
{
  [[CPApplication sharedApplication]
     beginSheet:loginWindow
     modalForWindow:theWindow
     modalDelegate:nil
     didEndSelector:nil
     contextInfo:nil];
}

- (IBAction)tryLogin:(id)sender
{
  if([loginUsername stringValue] == ""){
    [loginStatus setStringValue:"ERROR: Username Required"];
    return;
  }
  if([loginPassword stringValue] == ""){
    [loginStatus setStringValue:"ERROR: Password Required"];
    return;
  }
  wantsController = true;
  [loginStatus setStringValue:"Logging in..."];
  [icon loginToServer:ICON_SERVER
        login:[loginUsername stringValue]
        password:[loginPassword stringValue]
        path:[self showPath]];
}

- (IBAction)endLogin:(id)sender
{
  CPLog("Ending Login");
  [loginStatus setStringValue:""];
  [[CPApplication sharedApplication] endSheet:loginWindow];
  [loginWindow performClose:self];
}

- (IBAction)goToFullScreen:(id)sender
{
  [slideController fullScreen];
}

@end
