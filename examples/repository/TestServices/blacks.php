<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();
  foreach($params as $p) {
    if($p->name() == "title") $title = $p->value();
    if($p->name() == "date") $date = $p->value();
  }
 

 $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<movieID>BLACK-".$title."-".rand(10,59)."</movieID>";
  $ret .= "<date>" . $date ."</date>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "<entry>";
  $ret .= "<movieID>BLACK-".$title."-".rand(10,59)."</movieID>";
  $ret .= "<date>" . $date ."</date>";
  $ret .= "<startingTime>" . rand(10,23) . ":".rand(10,59).":00</startingTime>";
  $ret .= "<price>" . rand(2,20) . "." . rand(0,99) . "</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it(200);
?>
