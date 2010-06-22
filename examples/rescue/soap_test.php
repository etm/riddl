<?php
ini_set("soap.wsdl_cache_enabled", "0");
$client = new SoapClient("http://localhost/Testservices/Scramble.wsdl");

$origtext = "mississippi";

print("The original text : $origtext");
$scramble = $client->getRot13($origtext);

print("The scrambled text : $scramble");

$mirror = $client->getMirror($scramble);
print("The mirrored text : $mirror");
?>
