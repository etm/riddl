<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/serversimple.php");

  print $includes;

  exit;

  $s = RiddlServerSimple.new();
  $s->add(RiddlParameterSimple.new("hello","world");
  $s->add(RiddlParameterSimple.new("hallo","ralph");
  $s->return();
?>
