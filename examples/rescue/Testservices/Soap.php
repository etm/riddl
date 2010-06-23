<?php
function getRot13($pInput){
$rot = str_rot13($pInput);return($rot);
}
function getMirror($pInput){
$mirror = strrev($pInput);

return($mirror);
}



// turn off the wsdl cache
ini_set("soap.wsdl_cache_enabled", "0");

$server = new SoapServer("Scramble.wsdl");

$server->addFunction("getRot13");
$server->addFunction("getMirror");

$server->handle();
?>
