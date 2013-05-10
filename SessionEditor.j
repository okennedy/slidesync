

@implementation SessionEditor : CPObject
{
  @outlet CPPanel editorPanel;
  @outlet CPTextField sessionName;
  @outlet CPTextField presentationURL;
  
  ICON icon;
  CPString sid;
}

- (id)initWithICON:(ICON)in_icon sessionID:(CPString)in_sid
{
  if(self = [super init]){
    var cib = [[CPCib alloc] initWithCibNamed:"SessionEditor"
                             bundle:[CPBundle mainBundle]];
    [cib instantiateCibWithOwner:self
         topLevelObjects:[CPArray array]];
    
    icon = in_icon;
    sid = in_sid;
    
    if(sid != nil){
      var info = [icon getPath:"slidesync/sessions/"+sid];
      if(info){
        if(info["name"]){ [sessionName setStringValue:info["name"]]; }
        if(info["slides"]){ [presentationURL setStringValue:info["slides"]]; }
      }
    }
  }
  return self;
}

- (void)startSheetForWindow:(CPWindow)win
{
  [[CPApplication sharedApplication]
     beginSheet:editorPanel
     modalForWindow:win
     modalDelegate:nil
     didEndSelector:nil
     contextInfo:nil];
}

- (void)endSheet
{
  [[CPApplication sharedApplication] endSheet:editorPanel];
  [editorPanel performClose:self];
  [editorPanel orderOut:self];
}

- (CPPanel)panel
{
  return editorPanel;
}

- (BOOL)validate
{
  if(["" isEqualToString:[sessionName stringValue]]){ 
    return NO;
  }
  if(["" isEqualToString:[presentationURL stringValue]]){ 
    return NO;
  }
  return YES;
}

- (IBAction)saveButton:(id)sender
{
  if(![self validate]){ return; }
  if(sid != nil){
    [icon writeToPath:"slidesync/sessions/"+sid+"/name"
          data:[sessionName stringValue]];
    [icon writeToPath:"slidesync/sessions/"+sid+"/slides"
          data:[presentationURL stringValue]];
  } else {
    [icon appendToPath:"slidesync/sessions"
          data: {
            "name" : [sessionName stringValue],
            "slides" : [presentationURL stringValue],
            "activeSlide" : 0
          }
    ];
  }
  [self endSheet];
}

- (IBAction)cancelButton:(id)sender
{
  [self endSheet];
}
@end