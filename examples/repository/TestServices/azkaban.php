<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");

//print_r($_GET);
/*
$myFile = "/home/ralph/www/testFile.txt";
$fh = fopen($myFile, 'w') or die("can't open file");
foreach($_GET as $key => $value){
fwrite($fh,$key . " => " . $value."\n");
}
fclose($fh);

$ret = "<you>are not working</you>";
*/
 $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<availability>true</availability>";
  $ret .= "<price>666.00</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s = new RiddlServerSimple();
  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it();
?>
