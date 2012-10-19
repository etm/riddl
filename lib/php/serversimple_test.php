<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request(); 

  ob_start();
  phpinfo();
  file_put_contents("serversimple_test.html", ob_get_contents());
  ob_end_clean();

  ob_start();
  print_r($params);
  file_put_contents("serversimple_parameters.txt", ob_get_contents());
  ob_end_clean();

  $s->add(new RiddlParameterComplex("hello","text/html","hello <b>world</b>"));
  $s->add(new RiddlParameterSimple("hallo","ralph"));
  $s->riddl_it(200);
?>
