<?
  header("Content-type: text/plain");
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/client.php");

  $s = new RiddlClient("http://localhost/serversimple_test.php");
  $ret = $s->post(array(
    new RiddlParameterSimple("hello","world")
  ));
  print "############################\n";
  print_r($ret);
?>
