<?php
  $includes = realpath(dirname(__FILE__));
  include_once($includes . "/../../../lib/php/client.php");

  $dom = NULL;
?>
<html>
  <head>
    <title>RESCUE Admin</title>
  </head>
  <body>
    <h1>RESCUE Admin</h1>
    <form enctype="multipart/form-data" name="request-form" method="POST" action="http://localhost/general-admin.php">
      <?php
        global $dom;
        $ok = true;

        // Load and verify description
        selectDescription();
        if(isset($_POST['rescue:descURI'])) {
          if(parseDescription() == false) {
            echo "\n<br/>The entered URI does not respond a valid description.<br/>";
            $ok = false;
          }
        }

        // Select message
        if($dom != NULL && $ok == true) {
          selectResMessage();
        }
        // build from
        if(isset($_POST['rescue:message']) && $ok == true) {
          createFormByMessage($_POST['rescue:message']);
        }
      ?>
      <br/>
      <input type="submit" value="Next"><br/><br/><br/>
      <img src="rescue.jpg" width="200" height="250"/>
      <?php
        if(isset($_POST['rescue:requestButton'])) {
          request();
        }
      ?>
    </form>
  </body>
</html>




<?php
  function selectDescription() {
    echo "\nURI of description file (server root URI):" . "<input name=\"rescue:descURI\" type=\"text\" value=\"" . $_POST['rescue:descURI'] . "\"/><br/>";
  }

  function parseDescription() {
    global $dom;

    $dom = new DomDocument();
    $dom->load($_POST['rescue:descURI']);
    
    ob_start();
    $erfolg = $dom->relaxNGValidate(realpath(dirname(__FILE__)) . "/../../../ns/description-1_0.rng");
    $fehler = ob_get_contents();
    ob_end_clean();
    if($erfolg == false) $dom = NULL;
    return $erfolg;

  }

  function selectResMessage() {
    global $dom;

    $root = $dom->documentElement;
    $rootResource = $root->getElementsByTagname($tagName)->item(0);
    echo "\nPlease select message from below:<br/>";
    echo "\n<select name=\"rescue:message\">";
    createResourceGroup($root, "1");
    echo "\n</select></br></br>";
  }

  function createResourceGroup($node, $id) {
    $label = $node->getAttribute("relative");
    $index = 1; 
    if($label == "") { $label = "dynamic";}
    echo "\n<optgroup label=\"" . $id . " " . $label . "\">";
  
    foreach($node->childNodes as $child) {
      if(($child->tagName == "get") || ($child->tagName == "post") || ($child->tagName == "put") || ($child->tagName == "delete")) {
        echo "\n<option value=\"" . $child->tagName . ":" . $child->getAttribute("in");
        if($_POST['rescue:message'] == $child->tagName . ":" . $child->getAttribute("in")) {
           echo "\" selected>";
        } else {
           echo "\">";
        }
        echo     $child->tagName . ": " .
             "Input: " . $child->getAttribute("in") .
             "</option>";
      } elseif($child->tagName == "resource") {
        createResourceGroup($child, $id . "." . $index);
        $index++;
      }
    }
    echo "\n</optgroup>";
  }

  function createFormByMessage($message) {
    global $dom;

    $messageElement = NULL;
    $root = $dom->documentElement;
    $messages = $root->getElementsByTagname("message");

    $method = substr($message, 0, strpos($message, ":"));
    $messageName = substr(strrchr($message, ":"), 1);

    foreach($messages as $m) {
      if($m->getAttribute('name') == $messageName) {
        $messageElement = $m;
      }
    }
    echo "\nEnter resource-path: " . "<input name=\"rescue:resPath\" type=\"text\" value=\"" . $_POST['rescue:resPath'] . "\"/><br/>";
    echo "\n<b>Method used for the request: " . $method;
    echo "\n<input name=\"rescue:method\" type=\"hidden\" value=\"" . $method . "\"/>";
    echo "\n<h3>Enter parameter value for " . $messageName . "</h3>";
    echo "\n<table>";
    foreach($messageElement->childNodes as $param) {
      if($param->tagName == "parameter") {
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

    echo "<h2>\nInput:</h2>";
    echo "<br/>\nURI:" . $_POST['rescue:descURI'] . $_POST['rescue:resPath'];
    echo "<br/>\nMETHOD:" . $_POST['rescue:method'];
    echo "<br/>\nParams:";
    echo "<br/>\n<pre>";
    echo "\n<textarea rows=\"10\" cols=\"80\" readonly=\"readonly\"/>";
    print_r($what);
    echo "\n</textarea>";
    echo "\n</pre>";

    echo "\n<h2>\nReturn Value:</h2>";
    $client = new RiddlClient($_POST['rescue:descURI']);
    $client->resource($_POST['rescue:resPath']);
    $return = $client->request($_POST['rescue:method'], $what);

    echo "\n<table>";
    foreach($return as $p) {
      echo "\n<tr><td><h3>Parameter with name: " . $p->name() . "\n</h3></td></tr>";
      if(get_class($p) == "RiddlParameterSimple") {
         echo "\n<tr><td>Value: " . $p->value() . "</td></tr>";
      }
      if(get_class($p) == "RiddlParameterComplex") {
        echo "\n<tr><td>";
        $s =  fread($p->value(), $p->size());
        echo "\n<textarea rows=\"10\" cols=\"80\" readonly=\"readonly\" value=\"" . $s . "\"/>";
        echo "\n</textarea>";
        echo "\n</td></tr>";
      }
    }
    echo "</table>";
  }
?>

