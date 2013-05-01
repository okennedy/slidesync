<?= "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ?>
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?
error_reporting(E_ERROR);
$stages = array(
  "Welcome to Hugin",
  "Database Settings",
  "Advanced Settings",
  "Settings File",
  "Validation"
);

$stage = 0;
if(isset($_GET["stage"])){
  $stage = $_GET["stage"] * 1;
}
if(isset($_POST["stage_name"])){
  $stage_name = $_POST["stage_name"];
  for($i = 0; $i < count($stages); $i++){
    if(("<< ".$stages[$i]." <<" == $stage_name) ||
       (">> ".$stages[$i]." >>" == $stage_name) ||
       ($stages[$i] == $stage_name)){
      $stage = $i;
    }
  }
}

function title($delta = 0){
  global $stage, $stages;
  if((($stage + $delta) < count($stages)) &&
     (($stage + $delta) >= 0)){
    return $stages[$stage + $delta];
  } else {
    return "Stage ".($stage+$delta);
  }
}

function random_string($l = 20){
    $c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxwz0123456789";
    for(;$l > 0;$l--) $s .= $c{rand(0,strlen($c))};
    return str_shuffle($s);
}

$option_info = array(
  "ICON_DB_DRIVER" => array("mysql", "string"),
  "ICON_LOCAL_AUTH_STRING" => array(random_string($l = 20), "string"),
  "ICON_LOGIN_TIMEOUT" => array(300, "integer"),
  "ICON_LOGIN_REFRESH" => array(60, "integer"),
  "ICON_DB_SERVER" => array("localhost", "string"),
  "ICON_DB_DBNAME" => array("ICON", "string"),
  "ICON_DB_ACCOUNT" => array("ICON", "string"),
  "ICON_DB_PASSWD" => array("", "string")
);
$option_values = array();
$option_types = array();
foreach($option_info as $option => $default){
  if(isset($_POST[$option])){
    $option_values[$option] = $_POST[$option];
  } else {
    $option_values[$option] = $default[0];
  }
  $option_types[$option] = $default[1];
}

function db_connect(){
  global $ICON_DB_DBNAME, $ICON_DB_DRIVER, $ICON_DB_SERVER, $ICON_DB_ACCOUNT, $ICON_DB_PASSWD;
  
  switch($ICON_DB_DRIVER){
    case "mysql":
      if(!mysql_connect($ICON_DB_SERVER, $ICON_DB_ACCOUNT, $ICON_DB_PASSWD)){
        return "ICON unable to connect to server: '$ICON_DB_ACCOUNT@$ICON_DB_SERVER': ".mysql_error();
      }
      if(!mysql_select_db($ICON_DB_DBNAME)){
        return "ICON database 'mysql://$ICON_DB_DBNAME' unavailable: ".mysql_error();
      }
      break;
    case "pgsql":
      if(!pg_connect("host=$ICON_DB_SERVER user=$ICON_DB_ACCOUNT password=$ICON_DB_PASSWD dbname=$ICON_DB_DBNAME")){
        return "ICON database 'pgsql://$ICON_DB_DBNAME' unavailable";
      }
      break;
    default:
      return "Unknown DB driver $ICON_DB_DRIVER";
  }
  return false;
}

function db_query($q){
//  error_log($q);
  global $ICON_DB_DRIVER;
  switch($ICON_DB_DRIVER){
    case "mysql":
      $ret = mysql_query($q);
      if(!$ret) { 
        return "(MY)SQL Error: ".mysql_error().$q;
      }
      return false;
    case "pgsql":
      $ret = pg_query($q);
      if(!$ret){
        return "(PG)SQL Error: ".pg_last_error().$q; 
      }
      return false;
    default:
      return "Unknown DB driver $ICON_DB_DRIVER";
  }
}

function db_fetch($r){
  global $ICON_DB_DRIVER;
  switch($ICON_DB_DRIVER){
    case "mysql":
      return mysql_fetch_array($r);
    case "pgsql":
      return pg_fetch_array($r);
  }
}

?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7" />
    <title>Hugin Setup: <?=title()?></title>


    <style type = "text/css">
        body {
          background-color:black;
        }
        .displaybox { 
          width:600px;
          text-align:left;
        }
        .header {
          max-width:50%;
          margin:0px;
          padding:10px;
          background-color:#484848;
          font-family: "Helvetica", "Arial", sans-serif; 
          font-size: 22px; 
          text-shadow: 3px 3px 0px grey;
          color:white;
        }
        .text {
          margin:0px;
          padding:10px;
          background-color:white;
          color:black;
        }
        .nav_left {
          padding-top:20px;
          float:left;
          text-align:left;
        }
        .nav_right {
          padding-top:20px;
          float:right;
          text-align:right;
        }
        .nav_box {
          height:50px;
        }
        td.field_title { 
          font-weight:bold;
          background-color:#cccccc;
          padding:5px;
        }
        td.field_input { 
          background-color:#eeeeee;
        }
        table.test_table {
          width:300px;
        }
        td.test_title {
          padding-right:10px;
          text-align:right;
          width:200px;
          background-color:#eeeeee;
        }
        td.test_result {
          padding-left:10px;
          text-align:left;
          font-weight:bold;
          width:50px;
          text-align:center;
          background-color:#aaaaaa;
        }
        td.test_resolution {
          padding: 10px 30px 10px 30px;
          background-color:#eeeeee;
          font-size: 14px;
        }
        table.test_conflict {
          font-size: 12px;
          border-collapse: collapse;
          border: 1px solid #666666;
          margin:10px;
          width:500px;
        }
        th.test_conflict {
          text-align:center;
          border-right: 1px solid #666666;
          border-bottom: 1px solid #666666;
        }
        td.test_conflict {
          border-right: 1px solid #666666;
          border-bottom: 1px solid #666666;
        }
    </style>

  </head>
  <body style="">
    <center>
    <form method="POST" action="setup.php">
    
    <div class="displaybox">
      <div class="header"><?=title()?></div>
      <div class="text">
<?
  function make_field($title, $text, $name){
    global $option_values;
    unset($option_values[$name]);
    return "<tr><td class=\"field_title\">$title</td><td class=\"field_input\">$text</td></tr>";
  }
  function make_input($title, $name, $type = "text"){
    global $option_values;
    $value = $option_values[$name];
    return make_field($title, 
                      "<input type=\"$type\" name=\"$name\" size=\"60\" value=\"$value\" \\>", 
                      $name);
  }
  function make_option($title, $name, $options){
    global $option_values;
    $text = "";
    foreach($options as $key => $opt){
      if($text != "") { $text .= "<br/>"; }
      $default = "";
      if($option_values[$name] == $key){ $default = " checked=\"YES\""; }
      $text .= "<input type=\"radio\" name=\"$name\" value=\"$key\"$default \\> $opt";
    }
    return make_field($title, $text, $name);
  }
  function generate_settings_file(){
    global $option_values, $option_types;
    $ret = "<?\n";
    foreach($option_values as $option => $value){
      if($option_types[$option] == "string"){
        $value = "\"$value\"";
      }
      $ret .= "\$$option = $value;\n";
    }
    $ret .= "?>\n";
    return $ret;
  }

  switch($stage){
    case 0: //intro
    ?>    
      <p>Welcome to Hugin.</p>
      
      <p>Hugin communicates through a shared object space 
      infrastructure named ICON.  Before using Hugin, we're going to have
      to get ICON running on your server.  You're going to need a few things:</p>
      <ul>
        <li>A database engine (Postgres and MySQL are supported)</li>
        <li>A database and account for ICON to use (don't use your root password)</li>
        <li>The ability to upload a file to the directory <tt>hugin/ICON</tt>.</li>
      </ul>
      
    <?  
      break;
      
    case 1: //database
    ?>
      <p>First, I need a little information about your database configuration.
      </p>
      <center><table>
        <?= make_option("Database Engine", "ICON_DB_DRIVER",
                        array("postgres" => "Postgres", "mysql" => "MySQL")); ?>
        <?= make_input("Server Address",   "ICON_DB_SERVER"); ?>
        <?= make_input("Database Name",    "ICON_DB_DBNAME"); ?>
        <?= make_input("Database Account", "ICON_DB_ACCOUNT"); ?>
        <?= make_input("Database Password","ICON_DB_PASSWD", "password"); ?>
      </table></center>
    <?
      break;
      
    case 2: //advanced settings
    ?>
      <p>You shouldn't need to change any of these settings.
      </p>
      <center><table>
        <?= make_input("Authentication Nonce", "ICON_LOCAL_AUTH_STRING"); ?>
        <?= make_input("Subscription Refresh Interval",
                       "ICON_LOGIN_REFRESH"); ?>
        <?= make_input("Login Timeout",        "ICON_LOGIN_TIMEOUT"); ?>
      </table></center>
    <?
      break;
      
    case 3: //generate settings file
    ?>
      <p>Create a file named <tt>hugin/ICON/ICON.prefs.php</tt> and copy the 
         following block of text into it:
      </p>
      <center><textarea rows="<?=count($option_values)+2?>" cols="70">
<?= generate_settings_file() ?></textarea></center>
    <?
      break;
    
    case 4: //setup ICON
      function run_test($test, $result, $correction, $warning = false) {
        if($result){
          $style = "color:green";
          $status = "OK";
        } else {
          if($warning){ 
            $style = "color:yellow";
            $status = "WARNING";
          } else {
            $style = "color:red";
            $status = "FAILED";
          }
          $status .= "</td></tr><tr>".
                     "<td colspan=2 class=\"test_resolution\">".
                     $correction."</td>";
        }
        ?><tr><td class="test_title"><?=$test?>: </td>
              <td class="test_result" style="<?=$style?>"><?=$status?></td>
              </tr><?
        return !$result;
      }
      
      echo "<table class=\"test_table\">";
      if(run_test("Checking for Prefs File",
          file_exists("ICON.prefs.php"),
          "I don't see a settings file.  Go back and generate the <input type=\"submit\" name=\"stage_name\" value=\"Settings File\" />."
      )){ echo "</table>"; break; }
      
      include "ICON.prefs.php";
      $conflicts = "";
      foreach($option_values as $option => $value){
        if($GLOBALS[$option] != $value){
          $conflicts .= "<tr><th class=\"test_conflict\">$option</th><td class=\"test_conflict\">$value</td><td class=\"test_conflict\">[concealed]</td></tr>";
        }
      }

      if(run_test("Validating Prefs File",
          strlen($conflicts) == 0,
          "Some options in the config file do not match the settings you gave me: <table class=\"test_conflict\"><tr><th class=\"test_conflict\">Option</th><th class=\"test_conflict\">Provided Setting</th><th class=\"test_conflict\">Config File</th></tr>$conflicts</table>  This might not be an issue.  Go back and regenerate the <input type=\"submit\" name=\"stage_name\" value=\"Settings File\" /> if a problem occurs.",
          true
      )){  }
      
      $conflicts = db_connect();
      if(run_test("Checking Database Connection", !$conflicts, $conflicts))
        { echo "</table>"; break; }
      
      $conflicts = db_query("SELECT 1");
      if(run_test("Verifying Database", !$conflicts, $conflicts))
        { echo "</table>"; break; }
      
      $conflicts = db_query("SELECT * FROM event");
      if(run_test("Checking for prior install", $conflicts, 
        "ICON has already been set up on this table.  Setup is complete.",
        true
      )) { echo "</table>"; break; }
      
      switch($ICON_DB_DRIVER){
        case "mysql":
          $conflicts = db_query(
            "CREATE TABLE `event` ( 
               `timestamp` int(11) NOT NULL auto_increment,
               `path` varchar(200) NOT NULL,
               `data` text NOT NULL,
               `action` enum('insert', 'delete') NOT NULL default 'insert',
               PRIMARY KEY (`timestamp`)
            ) AUTO_INCREMENT=4");
          if(!$conflicts){
            db_query(
              "INSERT INTO `event` (`timestamp`, `path`, `data`) VALUES
      ( 1, '/.auth', 
        '{\"read\":{\"anonymous\":\"YES\"},\"write\":{\"admin\":\"YES\"}}' ),
      ( 2, '/instances/.auth',
        '{\"read\":{\"anonymous\":\"YES\"},\"write\":{\"anonymous\":\"YES\"}}'),
      ( 3, '/users/admin','{\"password\":\"\"}' )");
          }
          break;
        case "postgres":
          $conflicts = "Auto postgres setup has not been completed yet.";
          break;
        default:
          $conflicts = "Unknown DB driver $ICON_DB_DRIVER";
          break;
      }
      if(run_test("Setting up ICON defaults", !$conflicts, $conflicts))
        { echo "</table>"; break; }
        
      echo "</table>";
      echo "<p>Hugin is now installed.  Use it <a href=\"../\">here</a></p>";

      break;
    
    default:
      echo "Bug in setup: Unknown stage '$stage';";
}
?>
<?

foreach($option_values as $option => $value){
?> <input type="hidden" name="<?=$option?>" value="<?=$value?>"/><?
}

?>
        <div class="nav_box">
        <? if($stage > 0) { ?>
          <div class="nav_left">
            <input type="submit" 
                   name="stage_name" 
                   value="<< <?=title(-1)?> <<"/>
          </div>
        <? } if($stage < count($stages) - 1) { ?>
          <div class="nav_right">
            <input type="submit" 
                   name="stage_name" 
                   value=">> <?=title(+1)?> >>"/>
          </div>
        <? } ?>
        </div>
      </div>
    </form>
    </center>
  </body>
</html>

