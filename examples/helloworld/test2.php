#!/usr/bin/php5
<?
  $fileContents = file_get_contents("test2.txt");
  $params = array(
     'http' => array
     (
         'method' => 'GET',
         'header'=> "Content-Type: multipart/related; boundary=\"paranguaricutirimirruaru0xdeadbeef\"\r\n",
         'content' => $fileContents
     )
  );
  $url = "http://localhost:9292/?someParam=someValue";
  $ctx = stream_context_create($params);
  $fp = fopen($url, 'rb', false, $ctx);
  
  $response = stream_get_contents($fp);
?>
