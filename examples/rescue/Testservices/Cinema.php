<?
  require_once("./serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "GET") == 0) { # A list of shows is returned 
    # Expected Parameters (in order): title, datei, prefix_id
    foreach($params as $p) {
      if($p->name() == "title")
        $title = $p->value();
      if($p->name() == "date")
        $date = $p->value();
      if($p->name() == "pre")
        $prefix = $p->value();
    }
    if($title == "") $title = "not given";
    if($date == "") $date = "not given";
    if($prefix == "") $prefix = "not given";
    $number_of_shows = rand(1, 5);
    $response = "<list_of_shows>\n";
    for($i = 0; $i < $number_of_shows; $i++) {
      $response .= "<show>";
      $response .= "<cinema_uri>".$_SERVER['REQUEST_URI']."</cinema_uri>";
      $response .= "<show_id>". $prefix ."_" . rand(1, 200). "</show_id>";
      $response .= "<title>". $title . "</title>";
      $response .= "<date>". $date . "</date>";
      $response .= "<time>". sprintf("%02d",rand(13, 23)) .":" . sprintf("%02d",rand(0, 3)*15) . "</time>";
      $response .= "</show>";
    }
    $response .= "</list_of_shows>";
    $s->add(new RiddlParameterComplex("out", "text/xml", $response));
  }
  if(strcasecmp($_SERVER['REQUEST_METHOD'], "POST") == 0) { # A reservation is made
    foreach($params as $p) {
      if($p->name() == "showID")
        $showID = $p->value();
    }
    $pre = explode("_", $showID);
    $resID = $pre[0] . "_" . rand(1, 200);
    $s->add(new RiddlParameterSimple("resID", $resID));
  }
  $s->riddl_it(200);
?>
