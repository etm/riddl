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

$boundary = "OneRingtobringthemallandinthedarknessbindthemIntheLandofMordorwheretheShadowslie0xdeadbeef";

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

$body = "--" . $boundary . "\n";


echo "<br/>Parameters";
foreach($request['parameters'] as $key=>$value) {
  echo "<br/>$key : $value";
  $body .= "content-disposition: form-data; name=\"$key\"\n\n$value\n--$boundary\n";
}
echo "<br/>Files";
foreach($request['files'] as $key => $value) {
  echo "<br/>$key : $value";
  $name = substr($key, 0, strpos($key, ":"));
  $mime = substr(strrchr($key, ":"), 1);
  $body .= "content-disposition: $mime; name=\"$name\"\n\n$value--$boundary\n";
}


echo "\n\n\n\n\n<h1>Message body</h1>\n\n\n";
echo $body;

  $req = array(
     'http' => array
     (
         'method' => $request['method'],
         'header'=> "Content-Type: multipart/related; boundary=\"$boundary\"\r\n",
         'content' => $body
     )
  );

  $url = "http://localhost:9292" . $argv[2];
  $ctx = stream_context_create($req);
  $fp = fopen($url, 'rb', false, $ctx);

  $response = stream_get_contents($fp);
  echo "<h1>Response</h1>\n";
  echo $response;
?>


</body>
</html> 
