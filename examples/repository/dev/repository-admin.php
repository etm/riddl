<html>
<body>

<h1>Output</h1>
<?php


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
echo "<br/>Method: {$request['method']}";
echo "<br/>URI: {$request['uri']}";
$request['parameters'] = $params;
$request['files'] = $files;

echo "<br/>Parameters";
foreach($request['parameters'] as $key=>$value) {
  echo "<br/>$key : $value";
}
echo "<br/>Files";
foreach($request['files'] as $key => $value) {
  echo "<br/>$key : $value";
}
?>


</body>
</html> 
