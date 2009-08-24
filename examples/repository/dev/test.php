<?php
  session_start();
?>

<html>
  <head>
    <title>RESCUE Admin</title>
  </head>
  <body>
    <h1>RESCUE Admin</h1>
    <form enctype="multipart/form-data" name="request-form" method="POST" action="http://localhost/test">
      <input type="text" name="PHPSESSID" value="<?=session_id()?>"><br/>

      <?php
        if((!isset($_POST['descURI'])) && (!isset($_SESSION['descURI']))) { // if no message has been selected
          selectDescription();
        } else {
          if(isset($_POST['descURI'] )) { $_SESSION['descURI'] = $_POST['descURI']; }
          if(!isset($_SESSION['description'])) {
            echo "\nThe description seems not to be valide. Pleas enter URI again.<br/>";
            selectDescription();
          } else {
            parseDescription();
            selectResMessage();
          }
          if(isset($_POST['message'])) {
            $_SESSION['message'] = $_POST['message'];
            createFormByMessage($_POST['message']);
          }
        }
      ?>
      <input type="submit" value=" Submit ">
    </form>
  </body>
</html>




<?php
  function selectDescription() {
    echo "\nInput URI of description file:" . "<input name=\"descURI\" type=\"text\"/><br/>";
  }

  function parseDescription() {
    global $validDesc;
    $dom = new DomDocument();
    $dom->load($_SESSION['descURI']);
    if ($dom->relaxNGValidate(realpath(dirname(__FILE__)) . "/../../../ns/description-1_0.rng")) {
      $_SESSION['description'] = $dom;
    }
  }

  function selectResMessage() {
    $dom = $_SESSION['description'];
    $root = $dom->documentElement;
    $rootResource = $root->getElementsByTagname($tagName)->item(0);
    echo "\n<select name=\"message\">";
    createResourceGroup($root, "1");
    echo "\n</select>";
  }

  function createResourceGroup($node, $id) {
    $label = $node->getAttribute("relative");
    $index = 1; 
    if($label == "") { $label = "dynamic";}
    echo "\n<optgroup label=\"" . $id . " " . $label . "\">";
  
    foreach($node->childNodes as $child) {
      if(($child->tagName == "get") || ($child->tagName == "post") || ($child->tagName == "put") || ($child->tagName == "delete")) {
        echo "\n<option value=\"" . $child->getAttribute("in") . "\">" .
             $child->tagName . ": " .
             "Input: " . $child->getAttribute("in") .
             "</option>";
      } elseif($child->tagName == "resource") {
        createResourceGroup($child, $id . "." . $index);
        $index++;
      }
    }
    echo "\n</optgroup>";
  }

  function createFormByMessage($messageName) {
    $dom = $_SESSION['description'];
    $root = $dom->documentElement;
    $messageElement = $root->getElementsByTagname($messageName)->item(0);
    echo "\n<h3>Enter parameter value for " . $messageName . "</h3>";
//get_class($messageElement)
    foreach($messageElement->childNodes as $param) {
      if($param->hasAttribute('type')) {  //Simple Parameter found
        echo "\n" . $param->getAttribute("name") . "<input name=\"" . $param->getAttribute("name") . "\" type=\"text\"/>";
      } 
      if($param->hasAttribute('mimetype')) {  //Complex Parameter found
        echo "\n" . $param->getAttribute("name") . "<input name=\"" . $param->getAttribute("name") . "\" type=\"file\"/>";
        echo "\n" . "<input name=\"" . $param->getAttribute("name") . "_mime\" type=\"text\" value=\"" . $param->getAttribute("mimetype") . "\"/>";
      } 
    }
  }
?>

