<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
</head>
<body>
<?php
  echo "Selected message: " . $_GET['message'];
  echo "Selected resource: " . $_GET['resource'];
?>
</body>
</html>

<?php
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

?>
