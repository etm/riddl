<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");

  $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<movieID>NURM-".$_GET['title']."-1</movieID>";
  $ret .= "<startingTime>17:15:00</startingTime>";
  $ret .= "<price>6.50</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>NURM-".$_GET['title']."-2</movieID>";
  $ret .= "<startingTime>18:15:00</startingTime>";
  $ret .= "<price>10.50</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s = new RiddlServerSimple();
  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it();
?>
