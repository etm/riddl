<?
  require_once("./serversimple.php");
  $s = new RiddlServerSimple();
  $params = $s->request();
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
    $response .= "<show_id>". $prefix ."_" . rand(1, 200). "</show_id>";
    $response .= "<title>". $title . "</title>";
    $response .= "<date>". $date . "</date>";
    $response .= "<time>". sprintf("%02d",rand(13, 23)) .":" . sprintf("%02d",rand(0, 3)*15) . "</time>";
    $response .= "</show>";
  }
  $response .= "</list_of_shows>";
  $s->add(new RiddlParameterComplex("out", "text/xml", $response));
  $s->riddl_it(200);
?>
