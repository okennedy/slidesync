// ICONObjectList
// 
// A simple interface built for managing object lists within ICON.
//
// Each ICONObjectList represents a sorted list of objects (located at a 
// particular point in the ICON tree) with append, delete, iterate, and lookup
// operations.  Objects are represented by actual ObjectiveJ objects, though 
// object management is still generally done using JS Objects (as in ICON).  
//
// ICONObjectList also includes an additional piece of functionality for dealing
// with network-associated lag, in particular with respect to insertions.  After
// an object is inserted into the list, it will appear in all iterations over
// the list until after it appears into the ICON root.  
//
// [constructorSelector]:(a:(CPString) b:(id) -> (id))
//   invoked on Constructor Target to translate a (key, JSObj) pair to its ObjJ 
//   representation.
//
// [updateSelector]:(id)
//   invoked on an ObjJ object to update its value.
// [deleteSelector]
//   invoked on an ObjJ object to indicate that it is about to be removed from 
//   the list.
// [commitSelector]
//   invoked on an ObjJ object to indicate that (being a temporary non-committed
//   object) its permanent replacement has been added to the ICON tree and
//   that it is about to be removed.
//
// --- Delegate Methods ---
// objectListChanged:(id)obj

@import "ICON.j"

@implementation ICONObjectList : CPObject
{
  CPString path;
  BOOL relative_path;
  ICON icon_hub;
  
  CPInvocation constructor;

  CPInvocation update_inv;
  CPInvocation delete_inv;
  CPInvocation commit_inv;
  
  id delegate;
  
  CPDictionary local_list;
  CPArray      temp_list;
}

- (id)initForHub:(ICON)in_icon_hub
      path:(CPString)in_path
      constructorTarget:(id)in_constructor_target
      constructorSelector:(SEL)in_constructor_sel
      updateSelector:(SEL)in_update_sel
      deleteSelector:(SEL)in_delete_sel
      commitSelector:(SEL)in_commit_sel
{
  if(self = [super init]){
    icon_hub = in_icon_hub;
    path = in_path;
    relative_path = YES;
    
    if(in_update_sel){
      update_inv = [[CPInvocation alloc] initWithMethodSignature:nil];
      [update_inv setSelector:in_update_sel];
    }
    
    if(in_delete_sel){
      delete_inv = [[CPInvocation alloc] initWithMethodSignature:nil];
      [delete_inv setSelector:in_delete_sel];
    }
    
    if(in_commit_sel){    
      commit_sel = [[CPInvocation alloc] initWithMethodSignature:nil];
      [commit_inv setSelector:in_commit_sel];
    }
    
    constructor = [[CPInvocation alloc] initWithMethodSignature:nil];
    [constructor setTarget:in_constructor_target];
    [constructor setSelector:in_constructor_sel];
    
    local_list = [[CPDictionary alloc] init];
    temp_list = [[CPArray alloc] init];
    
    [icon_hub registerForUpdatesToPath:[self path]
              target:self
              selector:@selector(listUpdated:)];
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

- (CPString)path
{
  if(relative_path){
    return [icon_hub path]+"/"+path;
  } else {
    return path;
  }
}

/////////////////////// BEGIN API ///////////////////////

- (id)insertObject:(id)v
{
  var obj = [self constructObject:"<temporary object>" value:v];
  [self insertNativeObject:obj value:v];
  return obj;
}

- (void)insertNativeObject:(id)obj value:(id)v
{
  var ts = [icon_hub immediateAppendToPath:[self path] data:v];
  [temp_list addObject:{
    timestamp : ts,
    object      : obj
  }];
}

- (void)asynchInsertObject:(id)v
{
  [icon_hub appendToPath:[self path] data:v];
}

- (void)updateKey:(CPString)key value:(id)v
{
  if(![local_list containsKey:key]){
    CPLog("Error: Update to unknown key %@ @ %@", key, [self path]);
    return;
  }
  [icon_hub writeToPath:([self path]+"/"+key) data:v];
}

- (CPEnumerator)objectEnumerator
{
  return [[ICONObjectListEnumerator alloc]
            initWithCoreList:[local_list objectEnumerator]
            tempList:[temp_list objectEnumerator]];
}

- (void)each:(id)f
{
  var iter, obj;
  iter = [self objectEnumerator];
  while(obj = [iter nextObject]){
    f(obj);
  }
}

- (int)objectCount
{
  return [local_list count] + [temp_list count];
}

- (void)objectAtIndex:(int)index
{
  if(index < [local_list count]){
    return [[local_list allValues] objectAtIndex:index];
  } else {
    return [temp_list objectAtIndex:(index - [local_list count])];
  }
}

- (void)objectForKey:(CPString)key
{
  return [local_list objectForKey:key];
}

- (void)deleteObjectForKey:(CPString)key
{
  [icon_hub deleteAtPath:[self path]+"/"+key];
}

/////////////////////// END API ///////////////////////

- (id)constructObject:(CPString)key value:(id)v
{
  [constructor setArgument:key atIndex:2];
  [constructor setArgument:v atIndex:3];
  [constructor invoke];
  return [constructor returnValue];
}

- (void)localDeleteKey:(CPString)key
{
  var obj = [local_list objectForKey:key];
  if(obj){
    [delete_inv invokeWithTarget:obj];
    [local_list removeObjectForKey:key];
  }
}

- (void)localUpdateKey:(CPString)key value:(id)v
{
  var obj = [local_list objectForKey:key];
  if(obj){
    [update_inv setArgument:v atIndex:2];
    [update_inv invokeWithTarget:obj];
  }
}

- (void)localInsertKey:(CPString)key value:(id)v
{
  [local_list setObject:[self constructObject:key value:v] forKey:key];
}

- (void)listUpdated:(id)new_list
{
  //CPLog("%@ updated with %@", path, new_list);
  if(new_list == nil){
    //clone the key list to protect it as things get deleted
    var iter = [local_list keyEnumerator];
    var key;
    while(key = [iter nextObject]){
      [self localDeleteKey:key];
    }
  } else {
    for(key in new_list){
      if(new_list[key]){
        if([local_list objectForKey:key]){
          [self localUpdateKey:key value:new_list[key]];
        } else {
          [self localInsertKey:key value:new_list[key]];
        }
      }
    } 
    //clone the key list to protect it as things get deleted
    var iter = [local_list keyEnumerator];
    var key;
    while(key = [iter nextObject]){
      if(new_list[key] == nil){
        [self localDeleteKey:key];
      }
    }
  }
  var i = 0;
  while(i < [temp_list count]){
    if([temp_list objectAtIndex:i].timestamp <= [icon_hub timestamp]){
      [commit_inv invokeWithTarget:[temp_list objectAtIndex:i].object]
      [temp_list removeObjectAtIndex:i];
    } else {
      i++;
    }
  }
}
@end

@implementation ICONObjectListEnumerator : CPObject
{
  CPEnumerator core_list;
  CPEnumerator temp_list;
}

- (id)initWithCoreList:(CPEnumerator)in_core_list 
      tempList:(CPEnumerator)in_temp_list
{
  if(self = [super init]){
    core_list = in_core_list;
    temp_list = in_temp_list;
  }
  return self;
}

- (id)nextObject
{
  if(core_list){
    var obj = [core_list nextObject];
    if(obj){ return obj; }
    else   { core_list = nil; }
  }
  if(temp_list){
    var obj = [temp_list nextObject];
    if(obj){ return obj.object; }
    else   { temp_list = nil; }
  }
  return nil;
}
@end