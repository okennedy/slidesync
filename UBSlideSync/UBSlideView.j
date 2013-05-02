@import <Foundation/CPObject.j>

@import "UBSlideCommandView.j"

@implementation UBSlideView : CPObject
{
  @outlet CPView slideView;
  @outlet CPTextView title;
  CPWebView contentView;
  UBSlideCommandView commandView;
  id content;
  id currSlide;
  CPString slideURL;
  
  id delegate;
}

- (id)init
{
  if(self = [super init]){
    var cib = [[CPCib alloc] initWithCibNamed:"SlideView"
                             bundle:[CPBundle mainBundle]];
    [cib instantiateCibWithOwner:self
         topLevelObjects:[CPArray array]];
    
    currSlide = 0;
    
    [self loadContent:"Slideshows/01-IntroAndModeling.json"];
  }
  return self;
}

- (void)setDelegate:(id)inDelegate
{
  delegate = inDelegate;
}

- (id)delegate
{
  return delegate;
}

- (void)awakeFromCib
{
  [slideView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
  contentView = [[CPWebView alloc] initWithFrame:[slideView frame]];
  [contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
  [slideView addSubview:contentView];
  commandView = [[UBSlideCommandView alloc] initWithSlideController:self];
  [slideView addSubview:commandView];
}

- (CPView)view
{
  return slideView;
}

- (CPView)commandView
{
  return commandView;
}

- (void)setContent:(id)newContent
{
  content = newContent;
  if((currSlide < 0) || (currSlide >= [content count])){ currSlide = 0; }
  [self loadSlide:currSlide];
}

- (void)loadContent:(CPString)url
{
  slideURL = url;
  var request = [CPURLRequest requestWithURL:url];
  var data = [CPURLConnection sendSynchronousRequest:request
                              returningResponse:nil];
  var jdata = [data JSONObject];
  if(jdata == null){
    CPLog.error("Invalid Content JSON: \n%@", [data rawString]);
  } else {
    [self setContent:jdata["slides"]];
  }
}

- (void)reloadContent
{
  if(slideURL != null) { [self loadContent:slideURL]; }
}

- (CPString)slideTitle
{
  return content[currSlide].title;
}

- (CPString)slideContent
{
  var titleText = [self slideTitle];
  if(titleText == nil){ titleText = ""; }
  else {
    titleText = "<tr height=\"100\" valign=\"middle\"><td align=\"center\">"+
                "<div class=\"present_title\">"+titleText+"</div></td></tr>";
  }
  return "<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\""+
  [[CPBundle mainBundle] pathForResource:"present.css"]+
  "\" /></head><body><table width=\"100%\" height=\"100%\">"+titleText+
  "<tr valign=\"middle\"><td align=\"center\">"+
  "<table><tr><td align=\"center\"><div class=\"present_content\">"+
  content[currSlide].content+
  "</div></td></tr></table>"+
  "</td></tr></table></body></html>"
}

- (void)formatSlide
{
  [contentView loadHTMLString:[self slideContent]];
}

- (void)stepForward
{
  [self loadSlide:currSlide+1];
}

- (void)stepBack
{
  [self loadSlide:currSlide-1];
}

- (void)loadSlide:(int)slide
{
  if((slide < 0) || (slide >= [content count])){
    CPLog.error("Invalid slide: %d", slide);
  } else {
    var changingSlide = (slide != currSlide);
    currSlide = slide;
    [self formatSlide];
    if(changingSlide){
      if([delegate respondsToSelector:@selector(slideView:loadedSlide:)]){
        [delegate slideView:self loadedSlide:slide];
      }
    }
  }
}

@end
