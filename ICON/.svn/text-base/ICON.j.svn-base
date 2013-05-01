
@implementation ICON : CPObject
{
  id rootObject;
  CPDictionary messageCallbacks;
  id subscription;
  int timestamp;
  CPString server;
  int sequenceNumber;
  id delegate;
  CPTimer refreshTimer;
  BOOL active;
  CPString username;
  CPString local_path;
}

- (id)initWithServer:(CPString)in_server 
      login:(CPString)in_login 
      password:(CPString)in_password
        path:(CPString)in_path
        depth:(int)depth
{
  if(self = [self init]){
    [self loginToServer:in_server 
          login:in_login 
          password:in_password
          path:in_path
          depth:depth];
  }
  return self;
}

- (id)initWithServer:(CPString)in_server 
      login:(CPString)in_login 
      password:(CPString)in_password
        path:(CPString)in_path
{
  return [self initWithServer:in_server
               login:in_login
               password:in_password
               path:in_path
               depth:nil];
}
- (id)init
{
  if(self = [super init]){
    messageCallbacks = [[CPDictionary alloc] init];
    rootObject = [[ICONObjectMonitor alloc] initWithObject:nil path:""];
    sequenceNumber = 0;
    timestamp = -1;
    active = true;
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

- (void)deactivate
{
  [refreshTimer invalidate];
  active = NO;
  refreshTimer = nil;
}

/////////////// UI
- (void)registerForUpdatesToPath:(CPString)path
        target:(CPString)target
        selector:(SEL)selector
{
  [rootObject registerForUpdatesToPath:[path ICONNormalizedPath]
              target:target selector:selector];
}

- (void)deleteAtPath:(CPString)path
{
  [self sendRequest:"delete"
        args:{ "subscription" : subscription,
               "path" : path }
        target:self
        successSelector:nil
        failSelector:@selector(requestFailure:)];
}

- (void)appendToPath:(CPString)path
        data:(id)data
{
  [self appendToPath:path 
        data:data 
        target:self 
        success:nil 
        fail:@selector(requestFailure:)];
}

- (int)immediateAppendToPath:(CPString)path
        data:(id)data
{
  var ret =
    [self immediateRequest:"append"
          args:{ "subscription" : subscription, 
                 "path" : path,
                 "data" : [CPString JSONFromObject:data] } ];
  if (ret == nil) { return nil; }
  if (ret.result == "failure"){
    CPLog("Error with immediate append: "+ret.reason);
    return nil;
  }
  return ret.timestamp;
}

- (void)appendToPath:(CPString)path
        data:(id)data
        target:(id)target
        success:(SEL)successSelector
        fail:(SEL)failSelector
{
  [self sendRequest:"append"
        args:{ "subscription" : subscription, 
               "path" : path,
               "data" : [CPString JSONFromObject:data] }
        target:target
        successSelector:successSelector
        failSelector:failSelector];
}

- (void)immediateWriteToPath:(CPString)path
        data:(id)data
{
  var ret =
    [self immediateRequest:"write"
          args:{ "subscription" : subscription, 
                 "path" : path,
                 "data" : [CPString JSONFromObject:data],
                 "safe" : "YES" }];
  if (ret == nil) { return nil; }
  if (ret.result == "failure"){
    CPLog("Error with immediate write: "+ret.reason);
    return nil;
  }
  return ret.timestamp;
}

- (void)writeToPath:(CPString)path
        data:(id)data
{
  [self writeToPath:path 
        data:data 
        safe:YES
        target:self 
        success:nil
        fail:@selector(requestFailure:)];
}

- (void)writeToPath:(CPString)path
        data:(id)data
        safe:(BOOL)safe_to_overwrite
        target:(id)target
        success:(SEL)successSelector
        fail:(SEL)failSelector
{
  [self sendRequest:"write"
        args:{ "subscription" : subscription, 
               "path" : path,
               "data" : [CPString JSONFromObject:data],
               "safe" : safe_to_overwrite ? "YES" : "NO" }
        target:target
        successSelector:successSelector
        failSelector:failSelector];
}

- (id)getUserlist
{
  var ret = [self immediateRequest:"list_users" args:{}];
  if(ret == nil) { return []; }
  if(ret.result == "failure"){
    CPLog("Error fetching userlist: "+ret.reason);
    return [];
  } else {
    return ret.users;
  }
}

- (id)readUserInfo
{
  var ret = [self immediateRequest:"read_user"
                  args:{ "user"         : [self username],
                         "subscription" : subscription }];
  if(ret == nil) { return []; }
  if(ret.result == "failure"){
    CPLog("Error fetching userlist: "+ret.reason);
    return [];
  } else {
    return ret.data;
  }
}

- (CPString)updatePasswordFrom:(CPString)old_password to:(CPString)new_password
{
  var ret = [self immediateRequest:"create_user"
                  args:{  "user"         : [self username],
                          "password"     : old_password,
                          "new_password" : new_password }];
  if(ret == nil) return "Unknown error";
  if(ret.result == "failure") return ret.reason;
  return nil;
}

- (id)getPath:(CPString)path
{
  return [rootObject get:[path ICONNormalizedPath]];
}

- (CPString)username
{
  return username;
}

- (void)moveToPath:(CPString)new_path depth:(int)depth
{
  [self deactivate];
  
  local_path = new_path;
  var args = { "subscription" : subscription,
               "path" : new_path };
  if(depth != nil){ args["depth"] = depth; } 
  
  [self sendRequest:"read"
        args:args
        target:self
        successSelector:@selector(loginSuccess:)
        failSelector:@selector(loginFailure:)];
}

- (void)moveToPath:(CPString)new_path
{
  [self moveToPath:new_path depth:nil];
}

- (CPString)path
{
  return local_path;
}

- (int)timestamp
{
  return timestamp;
}

//////////////// Internals
- (void)loginToServer:(CPString)in_server 
        login:(CPString)in_login 
        password:(CPString)in_password
        path:(CPString)in_path
        depth:(int)depth
{
  server = in_server;
  username = in_login;
  local_path = in_path;
  var args = { "user" : in_login, 
               "password" : in_password, 
               "path" : in_path };
  if(depth != nil){ args["depth"] = depth; } 
  
  [self sendRequest:"read"
        args:args
        target:self
        successSelector:@selector(loginSuccess:)
        failSelector:@selector(loginFailure:)];
}
- (void)loginToServer:(CPString)in_server 
        login:(CPString)in_login 
        password:(CPString)in_password
        path:(CPString)in_path
{
  [self loginToServer:in_server 
        login:in_login
        password:in_password
        path:in_path
        depth:nil];
}

- (void)sendRequest:(CPString)action
        args:(id)args
        target:(id)target
        successSelector:(SEL)success
        failSelector:(SEL)failure
{
  [self sendRequest:action args:args target:target 
        successSelector:success failSelector:failure
        immediate:NO];
}

- (void)immediateRequest:(CPString)action args:(id)args
{
  return [self sendRequest:action args:args target:nil
               successSelector:nil failSelector:nil
               immediate:YES];
}

- (id)sendRequest:(CPString)action
        args:(id)args
        target:(id)target
        successSelector:(SEL)success
        failSelector:(SEL)failure
        immediate:(BOOL)immediate
{
//  CPLog("Sending Request");
  var url = server+"?action="+action;
  
  if(!immediate){
    sequenceNumber += 1;
    args.user_ref = "" + sequenceNumber;
    [messageCallbacks setObject:{"success":success, 
                                 "failure":failure, 
                                 "target":target } 
                      forKey:"" + sequenceNumber];
  }

  var payload = "";
  var sep = "";
  for(i in args){
    payload += sep+i+"="+escape(args[i]); sep = "&";
  }
  var request = [[CPURLRequest alloc] initWithURL:url];
  [request setHTTPMethod:"POST"];
  [request setValue:"application/x-www-form-urlencoded"
           forHTTPHeaderField:"Content-Type"];
  [request setHTTPBody:payload];
  
  if(immediate){
    var data = [CPURLConnection sendSynchronousRequest:request
                                returningResponse:nil];
    return [data JSONObject];
  } else {
    [CPURLConnection connectionWithRequest:request delegate:self];
  }
}

- (void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
  [self requestFailure:{"reason" : "Connection Failed"}];
}

- (void)connection:(CPURLConnection)c didReceiveData:(CPString)data
{
//  CPLog("Got Data: %@", data);
  var obj = [data objectFromJSON];
  if(obj.subscription != nil){
    subscription = obj.subscription;
  }
  var cb = [messageCallbacks objectForKey:obj.user_ref];
  if(cb){
    var invocation = [[CPInvocation alloc] initWithMethodSignature:nil];
    if(obj.result == "success"){
      [invocation setSelector:cb.success];
    } else {
      [invocation setSelector:cb.failure];
    }
    if([invocation selector]){
      [invocation setTarget:cb.target];
      [invocation setArgument:obj atIndex:2];
      [invocation invoke];
    }
    [messageCallbacks removeObjectForKey:obj.user_ref];
  } else {
    CPLog("No message callback (%@): %@; data = '%@'", obj.user_ref, messageCallbacks, data);
  }
}

- (void)loginSuccess:(id)data
{
  timestamp = data.timestamp;

  if(rootObject == nil){
    rootObject = [[ICONObjectMonitor alloc] initWithObject:data.data path:""];
  } else {
    [rootObject put:data.data at:nil]
  }
  
  //CPLog("%@", [CPString JSONFromObject:[rootObject obj]]);
  if([delegate respondsToSelector:@selector(ICONLoginSuccess:)]){
    [delegate ICONLoginSuccess:self];
  }
  active = YES;
  [self delayedRefresh];
}

- (void)loginFailure:(id)data
{
  if([delegate respondsToSelector:@selector(ICONConnectionFailed:reason:)]){
    [delegate ICONConnectionFailed:self reason:data.reason];
  }
  CPLog("Login Failed: %@", data.reason);
}

- (void)requestFailure:(id)data
{
  if([delegate respondsToSelector:@selector(ICONRequestFailed:reason:)]){
    [delegate ICONRequestFailed:self reason:data.reason];
  }
  CPLog("Request Failed: %@", data.reason);
}

- (void)delayedRefresh
{
//  CPLog("Scheduling Refresh");
  if(!active){ return; }
  [refreshTimer invalidate];
  refreshTimer = 
    [CPTimer scheduledTimerWithTimeInterval:0.5
             target:self 
             selector:@selector(refresh)
             userInfo:nil
             repeats:NO];
}

- (void)refresh
{
//  CPLog("Sending Refresh");
  [self sendRequest:"poll"
        args:{ "subscription" : subscription }
        target:self
        successSelector:@selector(refreshSuccess:)
        failSelector:@selector(requestFailure:)];
}

- (void)refreshSuccess:(id)data
{
  var updates = [data.updates objectEnumerator];
  var u;
  
  timestamp = data.timestamp;
  
  while(u = [updates nextObject]){
    CPLog("Processing Update: %@ @ %@ : %@", u.action, u.path, u.data);
    [rootObject put:((u.action == "delete") ? undefined 
                                            : [u.data objectFromJSON]) 
                at:[u.path ICONNormalizedPath]];
  }
  
  [self delayedRefresh];
}

@end

@implementation CPString (ICONAdditions) 
- (CPArray)ICONNormalizedPath
{
  if([self length] > 0){
    if([self characterAtIndex:0] == "/"){
      return [[self substringFromIndex:1] pathComponents];
    }
  }
  return [self pathComponents];
}
@end


@implementation ICONObjectMonitor : CPObject
{
  id obj;
  CPArray callbacks;
  CPDictionary children;
  CPString local_path;
}

- (id)initWithObject:(id)in_obj path:(id)in_local_path
{
//  CPLog("Initializing monitor for %@ (initial object: %@)", in_local_path, in_obj);
  if(self = [super init]){
    obj = in_obj;
    local_path = in_local_path;
    callbacks = [[CPArray alloc] init];
    children = [[CPDictionary alloc] init];
  }
  return self;
}

- (ICONObjectMonitor)getChild:(CPString)name
{
  var child;
  if(child = [children objectForKey:name]){
    return child;
  } else {
    var child_obj = (obj == nil) ? nil : obj[name];
    child = [[ICONObjectMonitor alloc] initWithObject:child_obj path:local_path+"/"+name];
    [children setObject:child forKey:name];
    return child;
  }
}

- (id)obj
{
  return obj;
}

- (CPArray)pathPop:(CPArray)path
{
  return [path subarrayWithRange:CPMakeRange(1, [path count] - 1)];
}

- (id)get:(CPArray)path
{
  if([path count] == 0){
    return obj;
  } else {
    return [[self getChild:[path objectAtIndex:0]] 
              get:[self pathPop:path]];
  }
}

- (id)put:(id)in_obj at:(CPArray)path
{
//  CPLog("put %@ @ %@", [CPString JSONFromObject:in_obj], path);

  if((path == nil) || ([path count] == 0)){
    obj = in_obj;
    var childIter = [children keyEnumerator];
    var child;
    while(child = [childIter nextObject]){
      [[children objectForKey:child] 
        put:((obj == nil) ? nil : obj[child])
        at:nil];
    }
  } else {
    if(obj == nil){ obj = ["{}" objectFromJSON]; }
    [[self getChild:[path objectAtIndex:0]] 
      put:in_obj at:[self pathPop:path]];
    obj[[path objectAtIndex:0]] = [[self getChild:[path objectAtIndex:0]] obj];
  }
//  CPLog("Callbacks @ %@ size:%d", local_path, [callbacks count]);
  var cbIter = [callbacks objectEnumerator];
  var cb;
  while(cb = [cbIter nextObject]){
//    CPLog("Callback @ %@", local_path);
    [cb setArgument:obj atIndex:2];
    [cb invoke];
  }
}

- (void)registerForUpdatesToPath:(CPArray)path
        target:(id)target 
        selector:(SEL)selector 
{
//  CPLog("register %@ @ %@", target, path);
  
  if([path count] == 0){
    var cb = [[CPInvocation alloc] initWithMethodSignature:nil];
    [cb setTarget:target];
    [cb setSelector:selector];
    [callbacks addObject:cb];
    [cb setArgument:obj atIndex:2];
    [cb invoke];
//    CPLog("Callbacks @ %@ size:%d", local_path, [callbacks count]);
  } else {
    [[self getChild:[path objectAtIndex:0]] 
      registerForUpdatesToPath:[self pathPop:path]
      target:target
      selector:selector];
  }
}
@end