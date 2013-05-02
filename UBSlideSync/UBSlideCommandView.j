
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
  return YES;
}

- (void)keyUp:(CPEvent)evt
{
  if([[slideController delegate]
        respondsToSelector:@selector(slideViewShouldRespondToKeys:)]){
    if(![[slideController delegate] 
          slideViewShouldRespondToKeys:slideController]){
      return;
    }
  }
  switch([evt keyCode]){
    case 37: // left arrow
      [slideController stepBack];
      break;
    case 39: // right arrow
      [slideController stepForward];
      break;
    case 82: // 'r'
      [slideController reloadContent];
      break;
    case 27: // escape
      [slideController exitFullScreen];
      break;
    default:
      CPLog("Unused Keycode: %d", [evt keyCode]);
  }
}

- (void)mouseUp:(CPEvent)evt
{
  if([[slideController delegate]
        respondsToSelector:@selector(slideViewShouldRespondToMouse:)]){
    if(![[slideController delegate] 
          slideViewShouldRespondToMouse:slideController]){
      return;
    }
  }
  [slideController stepForward];
}

@end