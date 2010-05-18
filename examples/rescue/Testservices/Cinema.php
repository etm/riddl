<?
  require_once("./serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();
#  print_r($params);
#  error_log(print_r($_SERVER, 1));
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "GET") == 0) { # A list of shows is returned 
    # Expected Parameters (in order): title, datei, prefix_id
#error_log(print_r($params, 1));
    foreach($params as $p) {
      if($p->name() == "title")
        $title = $p->value();
      if($p->name() == "date")
        $date = $p->value();
      if($p->name() == "pre")
        $prefix = $p->value();
    }
#error_log("Title: " . $title);
#error_log("Date: " . $date);
#error_log("Prefix: " . $prefix);
    if($title == "") $title = "not given";
    if($date == "") $date = "not given";
    if($prefix == "") $prefix = "not given";
    $number_of_shows = rand(1, 5);
    $response = "<list_of_shows>\n";
    for($i = 0; $i < $number_of_shows; $i++) {
      $response .= "<show>";
      $response .= "<show_id>". $prefix ."_" . rand(1, 200). "</show_id>";
      $response .= "<title>". $title . "</title>";
      $response .= "<date>". $date . "</date>";
      $response .= "<time>". sprintf("%02d",rand(13, 23)) .":" . sprintf("%02d",rand(0, 3)*15) . "</time>";
      $response .= "</show>";
    }
    $response .= "</list_of_shows>";
error_log("Response: " . $response);    
    $s->add(new RiddlParameterComplex("out", "text/xml", $response));
  }
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "POST") == 0) { # A reservation is made
  }
  $s->riddl_it(200);
?>
