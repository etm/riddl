<html>
<body>

<?php
$includes = realpath(dirname(__FILE__));
include_once($includes . "/../../../lib/php/serversimple.php");

// while($element = each($_FILES)) {
//  echo $element[ 'key' ];
// echo ' - ';
// echo $element[ 'value' ];
// echo '<br />';
//}


$params = array();
$files = array();

$request = array();
  
$request['method'] = $_POST['method'];
$request['uri'] = $_POST['uri'];

while($element = each($_POST)) {
  if (substr($element['key'],0,11) == 'param_name_') {
    $name = $element['value'];
    $number = substr(strrchr($element['key'], "_"), 1);
    $value = $_POST["param_value_$number"];
    $params[$name] = $value;
  }
  if (substr($element['key'],0,10) == 'file_name_') {
    $name = $element['value'];
    $number = substr(strrchr($element['key'], "_"), 1);
    $value = file_get_contents($_FILES["file_value_$number"]['tmp_name']);
    $files[$name] = $value;
  }
}
//echo "<br/>Method: {$request['method']}";
//echo "<br/>URI: {$request['uri']}";
$request['parameters'] = $params;
$request['files'] = $files;

$s = new RiddlServerSimple("test.txt");

echo "<br/>Parameters\n";
foreach($request['parameters'] as $key=>$value) {
  echo "<br/>$key : $value\n";
  $s->add(new RiddlParameterSimple($key, $value));
}
echo "<br/>Files\n";
foreach($request['files'] as $key => $value) {
  $name = substr($key, 0, strpos($key, ":"));
  $mime = substr(strrchr($key, ":"), 1);
echo "Name: " . $name . " <br/>\n";
echo "MIME: " . $mime . " <br/>\n";
echo "Value:\n " . $value . "\n<br/>\n";
  $s->add(new RiddlParameterComplex($name, $mime, $value));
}


//  echo "<h1>Response</h1>\n";
  $s->riddl_it();
?>


</body>
</html> 
