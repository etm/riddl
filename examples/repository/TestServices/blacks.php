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
  $ret .= "<movieID>BLACK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>BLACK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s = new RiddlServerSimple();
  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it();
?>
