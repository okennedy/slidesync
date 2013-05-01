@implementation ICONTableViewManager : CPObject
{
  CPTableView table;
  CPArray contents;
  ICON icon;
  id sort;
  CPString path;
}

- (id)initWithTable:(CPTableView)in_table 
      path:(CPString)in_path 
      icon:(ICON)in_icon
{
  if(self = [super init]){
    table = nil;
    sort = nil;
    path = in_path;
    icon = in_icon;
    contents = [[CPArray alloc] init];
    [icon registerForUpdatesToPath:path
          target:self
          selector:@selector(contentsChanged:)];
    table = in_table;
    [table setDataSource:self];
  }
  return self;
}

- (void)sort
{
  if(sort){ [contents sortUsingFunction:sort context:nil]; }
}

- (id)setSortFunction:(id)in_sort context:ctx
{
  sort = function(a,b,ctx) { return in_sort(a.data,b.data,ctx); };
  [self sort];
  return self;
}

- (void)contentsChanged:(id)in_contents
{
  contents = [[CPArray alloc] init];
  for(var k in in_contents){
    if(in_contents[k]){
      [contents addObject:{ key:k, data:in_contents[k] }];
    }
  }
  [self sort];
  [table reloadData];
}

- (int)numberOfRowsInTableView:(CPTableView)aView
{
  return [contents count];
}

- (id)tableView:(CPTableView)aView 
      objectValueForTableColumn:(CPTableColumn)col
      row:(int)row
{
  if(row >= [contents count]){
    return ("<ERROR:row"+row+">");
  } else {
    var ident = [col identifier]
    if([ident isEqualToString:"row"]){
      return row+1;
    } if([ident isEqualToString:"key"]){
      var c = [contents objectAtIndex:row];
      return c.key;
    } else {
      var c = [contents objectAtIndex:row];
      return c.data[ident];
    }
  }
}

- (id)selectedDatum
{
  var row = [table selectedRow];
  if((row > -1) && (row < [contents count])){
    var c = [contents objectAtIndex:row];
    return c.data;
  }
  return nil;
}

- (CPString)selectedKey
{
  var row = [table selectedRow];
  if((row > -1) && (row < [contents count])){
    var c = [contents objectAtIndex:row];
    return c.key;
  }
  return nil;
}

- (void)tableView:(CPTableView)aView
        setObjectValue:(id)value
        forTableColumn:(CPTableColumn)col
        row:(int)row
{
  var c = [contents objectAtIndex:row];
  var new_data = {};
  
  for(var k in c.data){
    if(![k isEqualToString:[col identifier]]){
      new_data[k] = c.data[k];
    } 
  }
  new_data[[col identifier]] = value
  
  [icon writeToPath:path+"/"+c.key
        data:new_data];
}


@end