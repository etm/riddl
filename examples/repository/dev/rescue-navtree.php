<?php
class RESCUENavTree {
  private $id;
  private $rootURI;
  private $target;
  private $arrayIndex = 0;

  function __construct($id, $uri, $target) {
    $this->id = $id;
    $this->rootURI = $uri;
    $this->target = $target;
  }

  function generate() {
    $this->generateStyle();
    echo "<script type=\"text/javascript\" src=\"dtree.js\"></script>\n";
    echo "<div class=\"" . $this->id . "\">\n";
    echo "<script type=\"text/javascript\">\n";
    echo "var " . $this->id . " = new dTree('". $this->id . "');\n";
    echo $this->id . ".config.target = \"" . $this->target . "\";\n";
    $this->generateGroups();
    echo "document.write(" . $this->id . ");\n";
    echo "</script>\n";
    echo "</div>\n";
  }

  private function generateStyle() {
    echo "<style type=\"text/css\">\n";
    echo "." . $this->id . " {font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;font-size: 11px;color: #666;white-space: nowrap; }\n";
    echo "." . $this->id . " img {border: 0px;vertical-align: middle;}\n";
    echo "." . $this->id . " a {color: #333;text-decoration: none;}\n";
    echo "." . $this->id . " a:hover, " . $this->id . " a.nodeSel:hover {color: #333; text-decoration: underline;}\n";
    echo "." . $this->id . " a.nodeSel {background-color: #c0d2ec;}\n";
    echo "." . $this->id . " a.clip {overflow: hidden;}\n";
    echo "</style>\n";
  }
  private function getFeed($nameOfResource, $nameOfParam) {
    // Create new RIDDLCLient to receive feed of groups from repository
    $client = new RiddlClient($this->rootURI);
    $client->resource($nameOfResource);
    $return = $client->request("GET", $what);
    foreach($return as $p) {
      if($p->name() == $nameOfParam)
        $feed = fread($p->value(), $p->size());
    }
    $dom = new DomDocument();
    $dom->loadXML($feed);
    return $dom;
  }  

  // rootURI is with the resource groups e.g. http://localhost:9292/
  private function generateGroups() {
    $dom = $this->getFeed("groups", "list-of-groups");
    $entries = $dom->getElementsByTagName("entry");
    // Create a node named Groups
    $this->generateTreeEntry(-1, "Groups");
    foreach($entries as $entry) {
      $name = $entry->getElementsByTagName("id")->item(0)->nodeValue;
      $this->generateTreeEntry(0, $name);
      $this->generateSubgroups("groups/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    } 
  }

  private function generateTreeEntry($parentIndex, $name, $link = "") {
    echo $this->id . ".add(" . ($this->arrayIndex) . "," . $parentIndex . ",'" . $name . "','" . $link . "');\n";
    $this->arrayIndex++;
  }




  function generateSubgroups($resourcePath, $parentIndex) {
  
    // Create nodes for Schema entries
    $this->generateTreeEntry($parentIndex, "Properties" , $this->rootURI . $resourcePath . "?properties");
    $this->generateTreeEntry($parentIndex, "queryInput" , $this->rootURI . $resourcePath . "?queryInput");
    $this->generateTreeEntry($parentIndex, "queryOutput" , $this->rootURI . $resourcePath . "?queryOutput");
    $this->generateTreeEntry($parentIndex, "invokeInput" , $this->rootURI . $resourcePath . "?invokeInput");
    $this->generateTreeEntry($parentIndex, "invokeOutput" , $this->rootURI . $resourcePath . "?invokeOutput");

    $dom = $this->getFeed($resourcePath, "list-of-subgroups");
    $entries = $dom->getElementsByTagName("entry");
    foreach($entries as $entry) {
      $this->generateTreeEntry($parentIndex, $entry->getElementsByTagName("id")->item(0)->nodeValue);
      $this->generateServices($resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    }
  }


  function generateServices($resourcePath, $parentIndex) {

    $dom = $this->getFeed($resourcePath, "list-of-services");
    $entries = $dom->getElementsByTagName("entry");
    foreach($entries as $entry) {
      $this->generateTreeEntry($parentIndex, $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->rootURI . $resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue);
      $this->generateServiceDetails($resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    }
  }

  function generateServiceDetails($resourcePath, $parentIndex) {
    $dom = $this->getFeed($resourcePath, "details-of-service");
    $this->generateTreeEntry($parentIndex, "URI", $dom->getElementsByTagName("URI")->item(0)->nodeValue);
    $this->generateTreeEntry($parentIndex, "staticProperties", $dom->getElementsByTagName("staticProperties")->item(0)->nodeValue);
  }

}

?>
