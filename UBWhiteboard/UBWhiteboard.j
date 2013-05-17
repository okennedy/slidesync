
function renderLine(ctx, pts){
  var l = [];
  var i;
  for(i = 0; i < pts.length-1; i++){
    l.push(pts[i]);
    l.push(pts[i+1]);
  }
  CGContextStrokeLineSegments(ctx, l, l.length);
}


@implementation UBWhiteboard : CPView {
  ICON icon;
  CPString path;
  CPRect frameBase;
  id drag;
  id shapes;
  id delegate;
  
  BOOL allowsDraw;
  
  @outlet CPPanel sketchControls;
}

- (id)initWithICON:(ICON)in_icon frame:(CPRect)in_frame
{
  if(self = [super initWithFrame:in_frame]){
    icon = in_icon;
    path = nil;
    drag = nil;
    shapes = [];
    allowsDraw = nil;
    var cib = [[CPCib alloc] initWithCibNamed:"UBWhiteboard"
                             bundle:[CPBundle mainBundle]];
    [cib instantiateCibWithOwner:self
         topLevelObjects:[CPArray array]];
    
    [sketchControls setDelegate:self];
  }
  return self;
}

- (void)setDelegate:(id)in_delegate
{
  delegate = in_delegate;
}

- (id)delegate
{
  return delegate;
}

- (id)registerAtPath:(CPString)in_path
{
  path = in_path;
  [icon registerForUpdatesToPath:path+"/frame"
        target:self
        selector:@selector(setFrameBase:)];
  [icon registerForUpdatesToPath:path+"/shapes"
        target:self
        selector:@selector(graphicsUpdated:)];
  return self;
}
- (void)unregister
{
  [icon unregisterForUpdatesToPath:path+"/frame" target:self];
  [icon unregisterForUpdatesToPath:path+"/shapes" target:self];
}



- (void)globalizeContext:(id)ctx
{
  var frame = [self frame];
  CGContextTranslateCTM(ctx, frameBase.origin.x, frameBase.origin.y);
  CGContextScaleCTM(ctx, frame.size.width / frameBase.size.width,
                         frame.size.height / frameBase.size.height);
}

- (void)drawRect:(CPRect)rect
{
  var context = [[CPGraphicsContext currentContext] graphicsPort];
  
  CGContextSaveGState(context);
    [self globalizeContext:context];
    CGContextSetLineWidth(context, 1);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetStrokeColor(context, [CPColor redColor]);
    if(drag && (drag.length > 1)){
      renderLine(context,drag);
    }
    var i;
    for(i in shapes){
      if('shapeType' in shapes[i]){
        switch(shapes[i].shapeType){
          case "line":
            renderLine(context,shapes[i].points);
            break; 
        }
      }
    }
  CGContextRestoreGState(context);

}

- (id)setFrameBase:(CPRect)in_frameBase
{
  if(in_frameBase == nil){ return; }
  var frameIsNew = 
    frameBase == nil ||
    (
      (in_frameBase.origin.x == frameBase.origin.x) &&
      (in_frameBase.origin.y == frameBase.origin.y) &&
      (in_frameBase.size.height == frameBase.size.height) &&
      (in_frameBase.size.width == frameBase.size.width)
    );

  
  frameBase = CPRectCreateCopy(in_frameBase);
  
  if(frameIsNew){
    if(path){
      [icon writeToPath:path+"/frame" data:in_frameBase];
    }
  }
  
  return self;
}

- (CPPoint)globalPointToLocal:(CPPoint)p
{
  var myFrame = [self frame];
  return CPPointMake(
    ((p.x - frameBase.origin.x) / frameBase.size.width) * myFrame.size.width,
    ((p.y - frameBase.origin.y) / frameBase.size.height) * myFrame.size.height
  );
}
- (CPPoint)localPointToGlobal:(CPPoint)p
{
  var myFrame = [self frame];
  return CPPointMake(
    ((p.x / myFrame.size.width) * frameBase.size.width) + frameBase.origin.x,
    ((p.y / myFrame.size.height) * frameBase.size.height) + frameBase.origin.y
  );
}

- (void)graphicsUpdated:(id)newGraphics
{
  shapes = newGraphics;
  [self setNeedsDisplay:YES];
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


- (void)mouseDown:(CPEvent)evt
{
  if(allowsDraw){
    drag = [ [self localPointToGlobal:[evt locationInWindow]] ];
  }
}
- (void)mouseDragged:(CPEvent)evt
{
  if(allowsDraw){
    drag.push([self localPointToGlobal:[evt locationInWindow]]);
    [self setNeedsDisplay:YES];
  }
}
- (void)mouseUp:(CPEvent)evt
{
  if(allowsDraw){
    drag.pop();
    if(path){
      [icon appendToPath:path+"/shapes"
            data:{"shapeType" : "line", "points" : drag }];
    }
    drag = nil;
  }
}

- (IBAction)clearWhiteboard:(id)sender
{
  [icon deleteAtPath:path+"/shapes"];
}

- (BOOL)windowShouldClose:(id)window
{
  if([delegate respondsToSelector:@selector(closeWhiteboard:)]){
    [delegate closeWhiteboard:self];
  }
  return YES;
}

- (void)activate:(id)sender
{
  if(allowsDraw){
    [sketchControls makeKeyAndOrderFront:self];
  }
}

- (void)setAllowsDraw:(BOOL)in_allowsDraw
{
  allowsDraw = in_allowsDraw;
}

@end