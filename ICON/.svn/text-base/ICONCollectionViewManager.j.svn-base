@implementation ICONCollectionViewManager : CPObject
{
  CPCollectionView table;
  CPArray contents;
  ICON icon;
  CPString path;
  CPString drag_type;
}

- (id)initWithCollectionView:(CPCollectionView)in_table 
      path:(CPString)in_path 
      icon:(ICON)in_icon
{
  if(self = [super init]){
    table = nil;
    path = in_path;
    icon = in_icon;
    contents = [[CPArray alloc] init];
    table = in_table;
    [icon registerForUpdatesToPath:path
          target:self
          selector:@selector(contentsChanged:)];
  }
  return self;
}

- (void)setDragType:(CPString)in_drag_type
{
  drag_type = in_drag_type;
}

- (CPString)dragType
{
  return drag_type;
}

- (CPArray)collectionView:(CPCollectionView)aCollectionView 
           dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
  if(drag_type){
    return [drag_type];
  } else {
    return [];
  }
}

- (CPData)collectionView:(CPCollectionView)aCollectionView 
          dataForItemsAtIndexes:(CPIndexSet)indices 
          forType:(CPString)aType
{
  var proto_object = 
    [[[aCollectionView items] objectAtIndex:[indices firstIndex]] view];
  var ret = 
    [CPData dataWithJSONObject:[proto_object miniDefn]];
  return ret
}

- (void)contentsChanged:(id)in_contents
{
  contents = [[CPArray alloc] init];
  for(var k in in_contents){
    if(in_contents[k]){
      [contents addObject:{ key:k, data:in_contents[k] }];
    }
  }
  [table setContent:contents];
}

- (id)selectedDatum
{
  var row = [[table selectionIndexes] firstIndex];
  if((row > -1) && (row < [contents count])){
    var c = [contents objectAtIndex:row];
    return c.data;
  }
  return nil;
}

- (CPString)selectedKey
{
  var row = [[table selectionIndexes] firstIndex];
  if((row > -1) && (row < [contents count])){
    var c = [contents objectAtIndex:row];
    return c.key;
  }
  return nil;
}

- (CPArray)selectedKeys
{
  var ret = [[CPArray alloc] init];
  var selected = [table selectionIndexes];
  var i;
  for(i = [selected firstIndex]; 
      i > 0; 
      i = [selected indexGreaterThanIndex:i]){
    [ret addObject:[contents objectAtIndex:i].key];
  }
  return ret;
}
  
@end