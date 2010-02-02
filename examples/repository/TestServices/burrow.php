<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/../../../lib/php/serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();


  $ret  = "<queryOutputMessage>\n";
  $ret .= "<entry>";
  if(rand(0,1) == 1) {
    $ret .= "<availability>true</availability>";
  } else {
    $ret .= "<availability>false</availability>";
  }
  $ret .= "<price>" . rand(20,200) . ".00</price>";
  $ret .= "</entry>";
  $ret .= "</queryOutputMessage>";

  $s->add(new RiddlParameterComplex("queryOutputMessage","text/xml", $ret));
  $s->riddl_it(200);
?>
