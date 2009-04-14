#!/usr/bin/php5
<?
  # Not Valid, always use multipart/form-data or www-x-form-encoded
  $fileContents = file_get_contents("description.xml");
  $params = array(
     'http' => array
     (
         'method' => 'POST',
         'header'=> "Content-Type: text/xml\r\nContent-disposition: riddl-data; name=\"description\"",
         'content' => $fileContents
     )
  );
  $url = "http://localhost:9292/?someParam=someValue";
  $ctx = stream_context_create($params);
  $fp = fopen($url, 'rb', false, $ctx);
  
  $response = stream_get_contents($fp);
?>
