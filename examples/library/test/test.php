#!/usr/bin/php5
<?
  $fileContents = file_get_contents($argv[3]);
  $params = array(
     'http' => array
     (
         'method' => strtoupper($argv[1]),
         'header'=> "Content-Type: multipart/related; boundary=\"paranguaricutirimirruaru0xdeadbeef\"\r\n",
         'content' => $fileContents
     )
  );
  $url = "http://localhost:9292/" . $argv[2];
  $ctx = stream_context_create($params);
  $fp = fopen($url, 'rb', false, $ctx);
  
  $response = stream_get_contents($fp);
?>
