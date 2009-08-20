<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/serversimple.php");

  $s = new RiddlServerSimple("test.text");
  $s->add(new RiddlParameterComplex("hello","text/html","hello <b>world</b>"));
#  $s->add(new RiddlParameterSimple("hallo","ralph"));
  $s->riddl_it();
?>
