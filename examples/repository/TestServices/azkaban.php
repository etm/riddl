<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();

  $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  $ret .= "<availability>true</availability>";
  $ret .= "<price>666.00</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it(200);
?>
