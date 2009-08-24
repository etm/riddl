<html>
<body>

<?php
$includes = realpath(dirname(__FILE__));
include_once($includes . "/../../../lib/php/client.php");

$what = array();

while($element = each($_POST)) {
  if (substr($element['key'],0,11) == 'param_name_') {
    $name = $element['value'];
    $number = substr(strrchr($element['key'], "_"), 1);
    $value = $_POST["param_value_$number"];
    array_push($what, new RiddlParameterSimple($name, $value));
  }
  if (substr($element['key'],0,10) == 'file_name_') {
    $name = substr($element['value'], 0, strpos($key, ":"));
    $mime = substr(strrchr($element['value'], ":"), 1);

    $number = substr(strrchr($element['key'], "_"), 1);
    $value = file_get_contents($_FILES["file_value_$number"]['tmp_name']);
    //$files[$name] = $value;
    array_push($what, new RiddlParameterComplex($name, $mime, $value));
  }
}

echo "<h2>\nInput:</h2>";
echo "<br/>\nURI:" . $_POST['uri'];
echo "<br/>\nMETHOD:" . $_POST['method'];
echo "<br/>\nParams:";
print_r($what);

$client = new RiddlClient("http://localhost:9292");
$client->resource($_POST['uri']);
$return = $client->request($_POST['method'], $what);

echo "\n<h2>\nReturnvalue:</h2>";
foreach($return as $p) {
  echo "\n<br/>" . $p->name() . ":";
  rewind($p->value());
  echo fread($p->value(), $p->size());
}
?>


</body>
</html> 
