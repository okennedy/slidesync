@implementation LogViewer : CPObject {
  ICON icon;
  CPArray events;
  
  @outlet CPView view;
  @outlet CPTableView logTable;
}

- (id)initWithICON:(ICON)in_icon
{
  if(self = [super init]){
    icon = in_icon;
    events = [[CPArray alloc] init];
    var cib = [[CPCib alloc] initWithCibNamed:"LogViewer"
                             bundle:[CPBundle mainBundle]];
    [cib instantiateCibWithOwner:self
         topLevelObjects:[CPArray array]];
    
    [logTable setDataSource:self];
    [[CPNotificationCenter defaultCenter]
      addObserver:self
      selector:@selector(iconUpdated:)
      name:"ICONUpdatePosted"
      object:icon];
  }
  return self;  
}

- (void)preload
{
  var request = 
    [[CPURLRequest alloc] initWithURL:[icon server]+"?action=events"];
  var data = 
    [CPURLConnection sendSynchronousRequest:request returningResponse:nil];
  
  data = [data JSONObject];
  
  if(data.result == "success"){
    var i;
    for(i = 0; i < data.updates.length; i++){
//      CPLog("%@", [CPString JSONFromObject:data.updates[i]]);
      [events addObject:data.updates[i]];
    }
  }
  [logTable reloadData];
}

- (id)iconUpdated:(CPNotification)notification
{
  [events addObject:[notification userInfo]];
  [logTable reloadData];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
  return [events count];
}

- (id)tableView:(CPTableView)aTableView 
      objectValueForTableColumn:(CPTableColumn)aColumn 
      row:(int)aRowIndex
{
  aRowIndex = [events count]-1-aRowIndex;
  var row = [events objectAtIndex:aRowIndex];
  var path = [[row.path substringFromIndex:1] stringByReplacingOccurrencesOfString:"/" withString:"."];
  
  if(row.action == "insert"){
    var summary = row.data;
    if([summary length] > 20){
      summary = [summary substringToIndex:17]+"...";
    }
    return [CPString stringWithFormat:"%@.write(%@)", path, summary];
  } else {
    return [CPString stringWithFormat:"%@.delete()", path];
  }
}

- (CPView)view
{
  return view;
}

@end