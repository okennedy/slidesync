/*
 * AppController.j
 * SlideSync
 *
 * Created by You on May 1, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@import "ICON/ICON.j"
@import "ICON/ICONTableViewManager.j"

@import "UBSlideSync/UBSlideView.j"
@import "UBWhiteboard/UBWhiteboard.j"

@import "SessionEditor.j"
@import "LogViewer.j"

ICON_SERVER = "ICON/ICON.php";

@implementation AppController : CPResponder
{
  @outlet CPWindow    theWindow; 
  @outlet CPPanel     loginWindow;
  @outlet CPTextField loginUsername; 
  @outlet CPTextField loginPassword;
  @outlet CPTextField loginStatus;
  @outlet CPMenuItem  loginMenuItem;
  
  @outlet CPTableView sessionList;
  @outlet CPTableColumn sessionNameColumn;
  @outlet CPTableColumn sessionURLColumn;
  @outlet CPView      sessionView;
  ICONTableViewManager sessionListManager;
  @outlet CPMenuItem  backToSessionMenuItem;
  
  @outlet CPMenuItem  startSketchingMenuItem;
  BOOL whiteboardActive;
  
  ICON icon;
  UBSlideView slideController;
  BOOL isController;
  BOOL wantsController;
  
  CPString session;
  
  UBWhiteboard whiteboard;
  
  LogViewer logViewer;
}

- (CPString)sessionPath
{
  return "slidesync/sessions/"+session;
}

- (CPString)whiteboardPath
{
  return [self sessionPath]+"/wb/slide_"+[slideController slideIndex];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
  // This is called when the application is done loading.
}

- (void)awakeFromCib
{
  [[theWindow contentView] 
    setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
  [theWindow setFullPlatformWindow:YES];
  
  isController = false;
  wantsController = false;

  icon = [[ICON alloc] initWithServer:ICON_SERVER
                       login:"anonymous"
                       password:""
                       path:""];
  [icon setDelegate:self];
  
  logViewer = [[LogViewer alloc] initWithICON:icon];
  [logViewer preload];
  
  whiteboard = [[UBWhiteboard alloc] initWithICON:icon
                                     frame:[[theWindow contentView] frame]];
  [whiteboard setFrameBase:CPRectMake(0,0,200.0,100.0)];
  [whiteboard setDelegate:self];
  whiteboardActive = NO;
  
  var args = [[CPApplication sharedApplication] arguments];
  
  session = nil;
  if([args count] > 0){ 
    session = [[args objectAtIndex:0] stringByReplacingOccurrencesOfString:"/"
                                      withString:""];
  }
  if(session == nil){
    [self setupPickSession];
  } else {
    [self setupSlideshow];
  }
}

- (IBAction)closeWhiteboard:(id)sender
{
  [whiteboard removeFromSuperview];
  whiteboardActive = NO;
  [whiteboard unregister];
  if(isController){
    [startSketchingMenuItem setEnabled:YES];
    [icon writeToPath:[self sessionPath]+"/whiteboardActive"
          data:NO];
  }
}

- (IBAction)openWhiteboard:(id)sender
{
  [[theWindow contentView] addSubview:whiteboard];
  [whiteboard registerAtPath:[self whiteboardPath]];
  whiteboardActive = YES;
  [whiteboard activate:self];
  if(isController){
    [startSketchingMenuItem setEnabled:NO];
    [icon writeToPath:[self sessionPath]+"/whiteboardActive"
          data:YES];
  }
}

- (void)moveWhiteboardToCurrentSlide
{
  [whiteboard unregister];
  [whiteboard registerAtPath:[self whiteboardPath]];
}


- (void)setupPickSession
{
  [backToSessionMenuItem setEnabled:NO];
  if(sessionListManager == nil){
    [sessionView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    sessionListManager = 
      [[ICONTableViewManager alloc] 
        initWithTable:sessionList
        path:"slidesync/sessions"
        icon:icon];
  }
  [sessionView setFrame:[[theWindow contentView] frame]];
  [[theWindow contentView] addSubview:sessionView];
}

- (IBAction)editSession:(id)sender
{
  var key = [sessionListManager selectedKey];
  if(key != nil){
    [[[SessionEditor alloc] initWithICON:icon sessionID:key]
      startSheetForWindow:theWindow];
  }
}

- (IBAction)createSession:(id)sender
{
  [[[SessionEditor alloc] initWithICON:icon sessionID:nil]
        startSheetForWindow:theWindow];
}

- (IBAction)deleteSession:(id)sender
{

}

- (IBAction)startSession:(id)sender
{
  var key = [sessionListManager selectedKey];
  if(key != nil){
    document.location.href = 
      [[document.location.href componentsSeparatedByString:"#"] 
        objectAtIndex:0]+"#"+key;
    session = key;
    [sessionView removeFromSuperview];
    [self setupSlideshow]
  }
}

- (IBAction)leaveSession:(id)sender
{
  [[slideController view] removeFromSuperview];
  [[logViewer view] removeFromSuperview];
  [icon unregisterForUpdatesToPath:[self sessionPath]+"/slides"
        target:self];
  [icon unregisterForUpdatesToPath:[self sessionPath]+"/activeSlide"
        target:self];
  [icon unregisterForUpdatesToPath:[self sessionPath]+"/whiteboardActive"
        target:self];
  session = nil;
  document.location.href = 
    [[document.location.href componentsSeparatedByString:"#"] 
      objectAtIndex:0]+"#";
  [self setupPickSession];
}

- (void)ICONLoginSuccess:(ICON)source
{
  CPLog("Login Successful");
  if(wantsController){
    [theWindow setInitialFirstResponder:[slideController commandView]];
    [self endLogin:self];
    [loginMenuItem setEnabled:NO];
    [sessionNameColumn setEditable:YES];
    [sessionURLColumn setEditable:YES];
    [whiteboard setAllowsDraw:YES];
    if(whiteboardActive){
      [whiteboard activate:self];
    } else {
      [startSketchingMenuItem setEnabled:YES];
    }
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
  [backToSessionMenuItem setEnabled:YES];
  slideController = [[UBSlideView alloc] init];
  
  var contentFrame = [[theWindow contentView] frame];
  
  
  [[slideController view] setFrame:
    CPMakeRect(contentFrame.origin.x,
               contentFrame.origin.y,
               contentFrame.size.width-400,
               contentFrame.size.height)];
      
  [[theWindow contentView] addSubview:[slideController view]];

  [[logViewer view] setFrame:
    CPMakeRect(contentFrame.origin.x+contentFrame.size.width-400,
               contentFrame.origin.y,
               400,
               contentFrame.size.height)];
  [[theWindow contentView] addSubview:[logViewer view]];

  [slideController setDelegate:self];
 
  [icon registerForUpdatesToPath:[self sessionPath]+"/slides"
        target:self
        selector:@selector(slidesUpdated:)];
  [icon registerForUpdatesToPath:[self sessionPath]+"/activeSlide"
        target:self
        selector:@selector(activeSlideUpdated:)];
  [icon registerForUpdatesToPath:[self sessionPath]+"/whiteboardActive"
        target:self
        selector:@selector(whiteboardActiveChanged:)];
}

- (void)whiteboardActiveChanged:(BOOL)nowActive
{
  if(!isController){
    if(nowActive != whiteboardActive){
      if(nowActive){
        [self openWhiteboard:self];
      } else {
        [self closeWhiteboard:self];
      }
    }
  }
}

- (void)slideView:(UBSlideView)view loadedSlide:(int)slide
{
  if(isController){
    CPLog("Updating global view to slide %d", slide);
    [icon writeToPath:[self sessionPath]+"/activeSlide"
          data:""+slide];
  } else {
    CPLog("Stepped to slide: %d", slide);
  }
  if(whiteboardActive){
    [self moveWhiteboardToCurrentSlide];
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
        path:""];
}

- (IBAction)endLogin:(id)sender
{
  CPLog("Ending Login");
  [loginStatus setStringValue:""];
  [[CPApplication sharedApplication] endSheet:loginWindow];
  [loginWindow performClose:self];
  [loginWindow orderOut:self];
}

- (IBAction)goToFullScreen:(id)sender
{
  [slideController fullScreen];
}

@end
