<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");

 $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK".$_GET['title']."-".rand(10,59)."</movieID>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s = new RiddlServerSimple();
  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it();
?>
