<?
require_once "ICON.prefs.php";

date_default_timezone_set('America/New_York');

function icon_failure($reason, $context = null){
  $ret = array(
    "result" => "failure",
    "reason" => $reason
  );
  $user_ref = get_arg("user_ref", null);
  if($user_ref != null){
    $ret["user_ref"] = $user_ref;
  }
  if($context != null){
    $ret["context"] = $context;
  }
  echo json_encode($ret); die();
}

switch($ICON_DB_DRIVER){
  case "mysql":
    mysql_connect($ICON_DB_SERVER, $ICON_DB_ACCOUNT, $ICON_DB_PASSWD) 
      or icon_failure("ICON unable to connect to server: '$ICON_DB_ACCOUNT@$ICON_DB_SERVER'");
    mysql_select_db($ICON_DB_DBNAME) 
      or icon_failure("ICON database 'mysql://$ICON_DB_DBNAME' unavailable");
      break;
  case "pgsql":
    pg_connect("host=$ICON_DB_SERVER user=$ICON_DB_ACCOUNT password=$ICON_DB_PASSWD dbname=$ICON_DB_DBNAME")
      or icon_failure("ICON database 'pgsql://$ICON_DB_DBNAME' unavailable");
    break;
}

function timestamp(){
  $ret = gettimeofday();
  return $ret["sec"];
}

function sanitize($text){
  global $ICON_DB_DRIVER;
  switch($ICON_DB_DRIVER){
    case "mysql":
      return mysql_escape_string($text);
    case "pgsql":
      return pg_escape_string($text);
  }
}

function query($q, $return_insert_id = false){
//  error_log($q);
  global $ICON_DB_DRIVER;
  switch($ICON_DB_DRIVER){
    case "mysql":
      $components = explode(";", $q);
      for($i = 0; $i < sizeof($components); $i++){
        if(rtrim($components[$i]) != ""){
          $ret = mysql_query($components[$i]);
          if(!$ret) { 
            error_log(mysql_error().";;;\n\n".$q); 
            icon_failure("(MY)SQL Error: ".mysql_error(), $components[$i]); 
          }
        }
      }
      if($return_insert_id){
        return mysql_insert_id();
      } else {
        return $ret;
      }
    case "pgsql":
      if($return_insert_id){
        #ugly hack... but nothing better for now
        $q .= "; SELECT CURRVAL('event_timestamp_seq')";
      }
      $ret = pg_query($q);
      if(!$ret){
        error_log(pg_last_error().";;;\n\n".$q); 
        icon_failure("(PG)SQL Error: ".pg_last_error(), $q); 
      }
      if($return_insert_id){
        $id = pg_fetch_array($ret);
        return $id[0];
      } else {
        return $ret;
      }
  }
}

function fetch_array($r){
  global $ICON_DB_DRIVER;
  switch($ICON_DB_DRIVER){
    case "mysql":
      return mysql_fetch_array($r);
    case "pgsql":
      return pg_fetch_array($r);
  }
}

function build_tree($obj, $path, $data, $depth = 1){
  if(sizeof($path) <= $depth) {
    return $data;
  }
  if($obj === null){
    if($data === null){ return null; }
    $obj = array();
  } elseif(!is_array($obj)){
    $obj = json_decode($obj, true);
  }
  
  $obj[$path[$depth]] = build_tree($obj[$path[$depth]], $path, $data, $depth+1);
  return $obj;
}

function tree_read_one($path){
  $result = query("SELECT * FROM event ".
                  "WHERE path = '/".sanitize($path)."' ".
                  "ORDER BY timestamp DESC ".
                  "LIMIT 1");
  if($row = fetch_array($result)){
    if($row["action"] == "insert"){
      return json_decode($row["data"], true);
    }
  }
  return array();
}

function tree_exists($path){
  return tree_read_one($path) != array();
}

function tree_delete_one($path){
  query("DELETE FROM event WHERE path LIKE '/".sanitize($path)."/%'".
        "                     OR path='/".sanitize($path)."';".
        "INSERT INTO event(path,action) VALUES ('/".
          sanitize($path)."','delete')");
}

function tree_write_one($path, $data){
  $ts = 
    query("INSERT INTO event(path,action,data) VALUES ('/".
          sanitize($path)."','insert','".sanitize(json_encode($data))."');", 
          true);
  query("DELETE FROM event WHERE (path='/".sanitize($path)."' ".
        "                     OR path LIKE '/".sanitize($path)."/%')".
        "                    AND timestamp < $ts;");
  return $ts;
}

function tree_read_query($path, $specific_file = null, $timestamp = -1, 
                         $internal_read = false){
  if($specific_file == null){
    $specific_file = "";
  } else {
    $specific_file = "/".sanitize($specific_file);
  }
  $secure_skips = "AND NOT PATH LIKE '/users/%' ";
  if($internal_read){
    $secure_skips = "";
  }
  $query = "SELECT * FROM event ".
           "WHERE path LIKE '/".sanitize($path)."%$specific_file' ".
           $secure_skips.
           "AND timestamp > ".($timestamp * 1)." ".
           "ORDER BY timestamp";
  return query($query);
}

function tree_read_all($path, $specific_file = null, &$timestamp = -1,
                       $internal_read = false){
  $result = tree_read_query($path, $specific_file, $timestamp, $internal_read);
  $obj = array();
  $max_ts = 0;
  while($row = fetch_array($result)){
    $max_ts = $row["timestamp"]; //results are sorted by timestamp
    switch($row["action"]){
      case "insert":
        $obj = build_tree($obj, explode("/", $row["path"]), json_decode($row["data"], true));
        break;
      case "delete":
        $obj = build_tree($obj, explode("/", $row["path"]), null);
        break;
    }
  }
  $timestamp = $max_ts;
  return $obj;
}

function tree_to_depth($obj, $depth){
  if($depth == -1){ return $obj; }
  if(!is_array($obj)){ return $obj; }
  if($depth < 1) { return array(); }
  $ret = array();
  foreach($obj as $field => $val){
    $ret[$field] = tree_to_depth($val, $depth-1);
  }
  return $ret;
}

function tree_scan($path, $file) {
  $path_parts = explode("/", $path);
  $query = "SELECT * FROM event";
  $sep = " WHERE ";
  $path = "";
  foreach($path_parts as $node){
    $path .= $node."/";
    $query .= $sep."path = '".sanitize($path).sanitize($file)."'";
    $sep = " OR ";
  }
  $result = query($query . " ORDER BY timestamp DESC");
  $ret = array();
  while($row = fetch_array($result)){
    if(!isset($ret[$row["path"]])){
      if($row["action"] == "delete"){
        $ret[$row["path"]] = "";
      } else {
        $ret[$row["path"]] = json_decode($row["data"], true);
      }
    }
  }
  return $ret;
}

function check_auth($auth_file, $user, $permission = "read"){
  if(isset($auth_file[$permission][$user]) &&
     ($auth_file[$permission][$user] == "YES")){
    return true;
  }
  if(($permission == "write") && 
     (!isset($auth_file["write"])) &&
     check_auth($auth_file, $user, "read")){
    return true;
  }
  if($user == "anonymous") { return false; }
  return check_auth($auth_file, "anonymous", $permission);
}

function authorize_tree($obj, $user, $max_depth = null){
  //this function doesn't special case the magical /users directory
  //however, the functions tree_read_query and tree_read_all will never 
  // return anything in /users
  if($max_depth != null){ if($max_depth <= 0) return array(); $max_depth -= 1; }
  if(!is_array($obj)){ return $obj; }
  if(isset($obj[".auth"])){
    if(!check_auth($obj[".auth"], $user)) { return null; }
  }
  $new_obj = array();
  foreach($obj as $subpath => $subobj){
    if($subpath[0] != "."){
      if(($ret = authorize_tree($subobj, $user, $max_depth)) !== null){
        $new_obj[$subpath] = $ret;
      }
    }
  }
  return $new_obj;
}

function authorize_write($path, $user){
  // special case the magical /users directory
  if(strncmp("users/",$path,6) == 0){
    return false; //all user operations done via the create_user action
  }
  
  $auth_files = tree_scan("/".$path, ".auth");
  foreach($auth_files as $authpath => $authdata){
    if(!check_auth($authdata, $user)) { 
      icon_failure("Unauthorized access");
    }
  }
  $path_parts = explode("/", "/".$path);
  
  for($i = 1; $i < sizeof($path_parts); $i++){
    $path_parts[$i] = $path_parts[$i-1]."/".$path_parts[$i];
  }
  for($i = sizeof($path_parts)-1; $i >= 0; $i--){
    if(isset($auth_files[$path_parts[$i]."/.auth"])){
      if(!check_auth($auth_files[$path_parts[$i]."/.auth"], $user, "write")){
        icon_failure("Unauthorized write");
      }
      return;
    }
  }
}

function authorize_read($path, $user, $explode_on_fail = true){
  // special case the magical /users directory
  if(strncmp("users/",$path,6) == 0){
    return false;
  }

  $auth_files = tree_scan("/".$path, ".auth");
  foreach($auth_files as $authpath => $authdata){
    if(!check_auth($authdata, $user)) { 
      icon_failure("Unauthorized access");
    }
  }
  return true;
}

function authorize_user($user, $password){
  if($user != "anonymous"){
    $user_info = tree_read_one("users/$user");
    if($user_info["password"] != sha1($password)){
      icon_failure("Incorrect Login");
    }
  }
}

function tok_auth_str($user, $timestamp, $path)
{
  global $ICON_LOCAL_AUTH_STRING;
  $tok_str = 
    str_replace("#", "\\#", str_replace("\\", "\\\\", $user)) . "#" .
    str_replace("#", "\\#", str_replace("\\", "\\\\", $path)) . "#" .
    $timestamp . "#" . $ICON_LOCAL_AUTH_STRING;
  return sha1($tok_str);
}

function gen_token($user, $timestamp, $path){
  $token = array(
    "user" => $user, 
    "timestamp" => $timestamp,
    "path" => $path,
    "token" => tok_auth_str($user, $timestamp, $path)
  );
  return base64_encode(json_encode($token));
}

function get_token($explode_on_invalid = true){
  $token = get_arg("subscription", null);
  if($token != null){
    $token = base64_decode($token);
    $token = json_decode($token, true);
    if($token != null){
      if($token["token"] != tok_auth_str($token["user"], $token["timestamp"], $token["path"])){
        icon_failure("Invalid Token Signature");
      } else {
        return $token;
      }
    }
  }
  if($explode_on_invalid){
    icon_failure("Invalid Token: ".get_arg("subscription", ""));
  }
  return null;
}

function get_arg($arg, $default){
  if     (isset($_GET[$arg] )) { return stripslashes($_GET[$arg]); }
  elseif (isset($_POST[$arg])) { return stripslashes($_POST[$arg]); }
  else                         { return $default; }
}

function get_path(){
  $path = get_arg("path", "");
  if($path[0] == "/"){ return substr($path,1); }
  return $path;
}

function get_login(){
  $subscription = get_token(false);
  if($subscription != null){
    return $subscription["user"];
  } else {
    $user = get_arg("user", "anonymous");
    authorize_user($user, get_arg("password", ""));
    return $user;
  }
}

//////////////////////////// CODE BEGINS HERE

$ret = array(
  "result" => "success",
);

switch(get_arg("action", "read")){
  case "ping":
    break;
  case "read":
    $user = get_login();
    $path = get_path();
    authorize_read($path, $user);
    $timestamp = -1;
    $obj = tree_read_all($path, null, $timestamp);
    $auth_list = array();
    $obj = authorize_tree($obj, get_login());
    $obj = tree_to_depth($obj, get_arg("depth", -1));
    $ret["data"] = $obj;
    $ret["subscription"] = gen_token($user, $timestamp, $path);
    $ret["timestamp"] = $timestamp;
    break;
  case "decode": //for debug use only
    $ret = get_token();
    break;
  case "sha1": //for debug use only
    $ret["sha1"] = sha1(get_arg("password", ""));
    break;
  case "create_user":
    $user = get_arg("user", null);
    $password = get_arg("password", null);
    $email = get_arg("email", null);
    if(($user == null) || ($password == null)){
      icon_failure("Invalid directive; User and Password MUST be supplied");
    }
    if(!tree_exists("users/$user")){
      $obj = array("password" => sha1($password));
      if($email != null){ $obj["email"] = $email; }
      tree_write_one("users/$user", $obj);
    } else {
      $new_password = get_arg("new_password", null);
      if($new_password == null){
        icon_failure("User already exists; Use new_password to set a new password");
      }
      authorize_user($user, $password);
      $obj = tree_read_all("users/$user", null, $timestamp, true);
      if( $obj != null && $obj["users"] != null && 
          ($obj["users"][$user] != null)){
        $obj = $obj["users"][$user];
      } else {
        $obj = array();
      }
      $obj["password"] = sha1($new_password);
      tree_write_one("users/$user", $obj);
    }
    break;
  
  case "list_users":
    $timestamp = -1;
    $user_dir = tree_read_all("users/", null, $timestamp, true);
    $ret["users"] = array();
    foreach($user_dir["users"] as $nick => $info){
      if($nick[0] != '.'){
        $ret["users"][] = array("nick" => $nick);
      }
    }
    break;
  
  case "read_user":
    $timestamp = -1;
    $user = get_login();
    if($user == "anonymous") {
      icon_failure("A login is required to edit your account");
    }
    $obj = tree_read_all("users/$user", null, $timestamp, true);
    if($obj == null || $obj["users"] == null || $obj["users"][$user] == null){
      icon_failure("User '$user' not found");
    }
    $obj = $obj["users"][$user];
    unset($obj["password"]);
    $ret["data"] = $obj;
    break;
  
  case "poll":
    $subscription = get_arg("subscription", null);
    if($subscription == null) { icon_failure("Missing subscription"); }
    $token = get_token();
    $result = tree_read_query($token["path"], null, $token["timestamp"]);
    $data = array();
    $new_timestamp = $token["timestamp"];
    while($row = fetch_array($result)){
      $new_timestamp = $row["timestamp"];
      $basename = basename($row["path"]);
      if($basename[0] != "."){
        if(authorize_read($row["path"], $token["user"], false)){
          $data[] = array(
            "action" => $row["action"],
            "path" => $row["path"],
            "data" => $row["data"]
          );
        }
      }
    }
    if($new_timestamp != $token["timestamp"]){
      $ret["subscription"] = gen_token($token["user"], 
                                       $new_timestamp, 
                                       $token["path"]);
    }
    $ret["timestamp"] = $new_timestamp;
    $ret["updates"] = $data;
    break;
  case "append":
    $user = get_login();
    $path = get_path();
    authorize_write($path, $user);
    
    if($path[strlen($path)-1] != "/") { $path .= "/"; }
    $now = gettimeofday();
    //this should properly handle 10 updates per second to a single structure
    $path .= $now["sec"]."_".rand(0,100);
    
    $data = json_decode(get_arg("data", ""), true);
    if($data == null){ icon_failure("Invalid data: '".get_arg("data", "")."'"); }
    $ret["timestamp"] = tree_write_one($path, $data);
    break;    

  case "write":
    $user = get_login();
    $path = get_path();
    authorize_write($path, $user);
    if(get_arg("safe", "NO") == "NO"){
      // yes, this is a race condition, but we can generally tolerate this 
      // kind of race.  At any rate, the needs of ICON are *NOT* well suited
      // to being implemented on top of a database.  Some sort of persistent
      // object store would be better, but that's not an option at the moment.
      $old = tree_read_one($path); 
      
      if($old != array()){
        icon_failure("File Exists");
      }
    }
    $data = json_decode(get_arg("data", ""), true);
    if($data == null){ icon_failure("Invalid data: '".get_arg("data", "")."'"); }
    $ret["timestamp"] = tree_write_one($path, $data);
    break;
  case "delete":
    $user = get_login();
    $path = get_path();
    authorize_write($path, $user, "write");
    tree_delete_one($path);
    break;
  default:
    $ret["result"] = "Invalid action (".get_arg("action", null).")";
    break;
}

$user_ref = get_arg("user_ref", null);
if($user_ref != null){
  $ret["user_ref"] = $user_ref;
}

?>
<?= json_encode($ret); ?>