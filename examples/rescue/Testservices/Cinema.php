<?
  require_once("./serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();
#  print_r($params);
#  error_log(print_r($_SERVER, 1));
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "GET") == 0) { # A list of shows is returned 
    # Expected Parameters (in order): title, datei, prefix_id
error_log(print_r($params, 1));
    $title = $params[0]->value();
    $date = $params[1]->value();
    $prefix = $params[2]->value();
  #error_log($prefix);
    $number_of_shows = rand(1, 5);
    $response = "<list_of_shows>\n";
    for($i = 0; $i < $number_of_shows; $i++) {
      $response .= "<show>\n";
      $response .= "<show_id>". $prefix ."_" . rand(1, 200). "</show_id>\n";
      $response .= "<title>". $title . "</title>\n";
      $response .= "<time>". sprintf("%02d",rand(14, 23)) .":" . sprintf("%02d",rand(0, 3)*15) . "</time>\n";
      $response .= "</show>\n";
    }
    $response .= "</list_of_shows>\n";
    $s->add(new RiddlParameterComplex("out", "text/xml", $response));
  }
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "POST") == 0) { # A reservation is made
  }
  $s->riddl_it(200);
?>
