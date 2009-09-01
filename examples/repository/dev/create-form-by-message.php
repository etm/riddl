<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<?php
  $includes = realpath(dirname(__FILE__));
  include_once($includes . "/../../../lib/php/client.php");
?>

<html>
<head>
</head>
<body>
<form enctype="multipart/form-data" name="request-form" method="POST" action="http://localhost/create-form-by-message.php">
<?php
  if(isset($_GET['resource']) || isset($_POST['rescue:resource'])) {
    createFormByMessage();
  } else {
    echo "<h2>Please choose a message from the tree on the right</h2>\n";
  }
  if(isset($_POST['rescue:requestButton'])) {
    request();
    // Reload tree-view
    echo "\n<script type=\"text/javascript\">";
    echo "\ntop.parent.frames['Navigation'].location=\"http://localhost/rescue-admin-tree.php\"";
    echo "\n</script>";
  }
?>
</form>
 
</body>
</html>

<?php
  function createFormByMessage() {

    echo "<input type=\"hidden\" name=\"rescue:resource\" value=\"";
    if(isset($_GET['resource'])) {
      $resource = $_GET['resource'];
    } else {
      $resource = $_POST['rescue:resource'];
    }
    echo $resource . "\"/>\n";

    echo "<input type=\"hidden\" name=\"rescue:method\" value=\"";
    if(isset($_GET['method'])) {
      $method =  $_GET['method'];
    } else {
      $method =  $_POST['rescue:method'];
    }
    echo $method . "\"/>\n";

    echo "<input type=\"hidden\" name=\"rescue:message\" value=\"";
    if(isset($_GET['message'])) {
      $message = $_GET['message'];
    } else {
      $message = $_POST['rescue:message'];
    }
    echo $message . "\"/>\n";

    echo "<h3>Meta-Data of request</h3>";
    echo "<b>Selected message:</b> " . $message ."<br/>\n";
    echo "<b>Selected method:</b>" . $method ."<br/>\n";
    echo "<b>Selected resource:</b> " . $resource ."<br/>\n";

    // Create new RIDDLCLient to receive feed of groups from repository
    $client = new RiddlClient("http://localhost:9292/");
    $return = $client->request("RIDDL", $what);
    $params = $return->parameters();
    $description = fread($params[0]->value(), $params[0]->size());
    $dom = new DomDocument();
    $dom->loadXML($description);
    $xpQuery = "/des:description/des:message[@name = \"" . $message . "\"]/*";
    $xp = new DomXPath($dom);
    $xp->registerNamespace("des", "http://riddl.org/ns/description/1.0");
    $parameters = $xp->query($xpQuery); 


    echo "<h3>Input request parameter</h3>";
    echo "\n<table>";
    foreach($parameters as $param) {
      echo "\n<tr>";
      if($param->hasAttribute('type')) {  //Simple Parameter found
        echo "\n<td>" . $param->getAttribute("name") . "</td><td>" .
             "<input name=\"" . $param->getAttribute("name") . "\" type=\"text\" value=\"" . $_POST[$param->getAttribute("name")] . "\"/></td>";
      } 
      if($param->hasAttribute('mimetype')) {  //Complex Parameter found
        echo "\n<td>" . $param->getAttribute("name") . "</td><td><input name=\"" . $param->getAttribute("name") . "\" type=\"file\"/>";
        echo "\n" . "<input name=\"rescue:" . $param->getAttribute("name") . "_mime\" type=\"hidden\" value=\"" . $param->getAttribute("mimetype") . "\"/></td>";
      } 
      echo "\n</tr>";
    }
    echo "\n<tr><td colspan=\"2\" align=\"center\"><input type=\"submit\" name=\"rescue:requestButton\" value=\"Perform request\"></td></tr>";
    echo "\n</table>";
  }

  function request() {
    
    $what = array();

    while($element = each($_POST)) {
      if(preg_match("/^rescue:(.*)_mime$/", $element['key'])) { // Complex found
        $name = array();
        preg_match("/^rescue:(.*)_mime$/",$element['key'], $name);
        $value = file_get_contents($_FILES[$name[1]]['tmp_name']);
        $p = new RiddlParameterComplex($name[1], $element['value'], $value);
        array_push($what, $p); 
      } 
      if(!strstr($element['key'], "rescue:")) {  // Simple found
          $p = new RiddlParameterSimple($element['key'], $element['value']);
          array_push($what, $p); 
      }
    }

    echo "<br/>\nParams:";
    echo "<br/>\n<pre>";
    echo "\n<textarea rows=\"10\" cols=\"80\" readonly=\"readonly\"/>";
    print_r($what);
    echo "\n</textarea>";
    echo "\n</pre>";

    echo "\n<h2>\nReturn Value:</h2>";
    $client = new RiddlClient("http://localhost:9292/");
    $client->resource($_POST['rescue:resource']);
    $return = $client->request($_POST['rescue:method'], $what);
     

    echo "\n<table>";
    $params = $return->parameters();
    foreach($params as $p) {
      echo "\n<tr><td><h3>Parameter with name: " . $p->name() . "\n</h3></td></tr>";
      if(get_class($p) == "RiddlParameterSimple") {
         echo "\n<tr><td>Value: " . $p->value() . "</td></tr>";
      }
      if(get_class($p) == "RiddlParameterComplex") {
        echo "\n<tr><td>";
        if ($p->size() > 0 ) $s =  fread($p->value(), $p->size());
        echo "\n<textarea rows=\"10\" cols=\"80\" readonly=\"readonly\" value=\"" . $s . "\"/>";
        echo "\n</textarea>";
        echo "\n</td></tr>";
      }
    }
    echo "</table>";
  }

?>
