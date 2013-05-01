
@implementation UBSlideCommandView : CPView
{
  UBSlideView slideController
}

- (void)initWithSlideController:(UBSlideView)inSlideController
{
  if(self = [super initWithFrame:[[inSlideController view] frame]]){
    slideController = inSlideController;
    [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self setHitTests:YES];
  }
  return self;
}

- (BOOL)acceptsFirstMouse:(CPEvent)evt
{
  return YES;
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (BOOL)becomeFirstResponder
{
  return YES;
}

- (BOOL)resignFirstResponder
{
  return NO;
}

- (void)keyUp:(CPEvent)evt
{
  switch([evt keyCode]){
    case 37:
      [slideController stepBack];
      break;
    case 39:
      [slideController stepForward];
      break;
    case 82:
      [slideController reloadContent];
      break;
    default:
      CPLog("Unused Keycode: %d", [evt keyCode]);
  }
}

- (void)mouseUp:(CPEvent)evt
{
  [slideController stepForward];
}

@end