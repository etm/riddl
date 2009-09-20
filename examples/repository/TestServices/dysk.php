<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");

 $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-1</movieID>";
  $ret .= "<startingTime>10:00:00</startingTime>";
  $ret .= "<price>10.50</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-2</movieID>";
  $ret .= "<startingTime>12:00:00</startingTime>";
  $ret .= "<price>11.50</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-3</movieID>";
  $ret .= "<startingTime>14:00:00</startingTime>";
  $ret .= "<price>16.50</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK-".$_GET['title']."-4</movieID>";
  $ret .= "<startingTime>16:00:00</startingTime>";
  $ret .= "<price>12.50</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>DYSK".$_GET['title']."-5</movieID>";
  $ret .= "<startingTime>18:00:00</startingTime>";
  $ret .= "<price>13.50</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s = new RiddlServerSimple();
  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it();
?>
