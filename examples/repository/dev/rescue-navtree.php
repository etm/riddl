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
    $this->includeScript();
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
    $this->generateTreeEntry(-1, "Rescue");
    $this->addSupportedMessages("/", 0);
    $this->generateTreeEntry(0, "Groups");
    $this->addSupportedMessages("/groups/", 2);
    foreach($entries as $entry) {
      $name = $entry->getElementsByTagName("id")->item(0)->nodeValue;
      $this->generateTreeEntry(2, $name);
      $this->generateSubgroups("/groups/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    } 
  }

  private function generateSubgroups($resourcePath, $parentIndex) {
    $dom = $this->getFeed($resourcePath, "list-of-subgroups");
    $entries = $dom->getElementsByTagName("entry");
    $this->addSupportedMessages("/". $resourcePath, $parentIndex);
    foreach($entries as $entry) {
      $this->generateTreeEntry($parentIndex, $entry->getElementsByTagName("id")->item(0)->nodeValue);
      $this->generateServices($resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    }
  }


  private function generateServices($resourcePath, $parentIndex) {
    $dom = $this->getFeed($resourcePath, "list-of-services");
    $entries = $dom->getElementsByTagName("entry");
    $this->addSupportedMessages($resourcePath . "/" , $parentIndex);
    foreach($entries as $entry) {
      $this->generateTreeEntry($parentIndex, $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->rootURI . $resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue);
      $this->generateServiceDetails($resourcePath . "/" . $entry->getElementsByTagName("id")->item(0)->nodeValue, $this->arrayIndex-1);
    }
  }

  private function generateServiceDetails($resourcePath, $parentIndex) {
//    $dom = $this->getFeed($resourcePath, "details-of-service");
    $this->addSupportedMessages("/" . $resourcePath, $this->arrayIndex-1);
//    $this->generateTreeEntry($parentIndex, "URI", $dom->getElementsByTagName("URI")->item(0)->nodeValue);
//    $this->generateTreeEntry($parentIndex, "staticProperties", $dom->getElementsByTagName("staticProperties")->item(0)->nodeValue);
  }


  private function generateTreeEntry($parentIndex, $name, $link = "") {
    echo $this->id . ".add(" . ($this->arrayIndex) . "," . $parentIndex . ",'" . $name . "','" . $link . "');\n";
    $this->arrayIndex++;
  }

  private function addSupportedMessages($resourcePath, $parentIndex) {
    $resourceLevel = substr_count($resourcePath, "/");
    // Create new RIDDLCLient to receive feed of groups from repository
    $client = new RiddlClient($this->rootURI);
    $return = $client->request("GET", $what);
    foreach($return as $p) {
      if($p->name() == "description")
        $feed = fread($p->value(), $p->size());
    }
    $dom = new DomDocument();
    $dom->loadXML($feed);
    $i = 0;
    $xpQuery = "/des:description";
    while($i < $resourceLevel) {
      $xpQuery .= "/des:resource";
      $i++;
    }
    $xpQuery .= "/*";
    $xp = new DomXPath($dom);
    $xp->registerNamespace("des", "http://riddl.org/ns/description/1.0");
    $entries = $xp->query($xpQuery); 
    foreach($entries as $entry) {
      if($entry->tagName != "resource") {
        $name = strtoupper($entry->tagName) . " (" . $entry->getAttribute("in") . " -> " . $entry->getAttribute("out") . ")";
        if($entry->tagName == "get") {
          if($entry->getAttribute("in") == "*") {
            $link = $this->rootURI . $resourcePath;
          } else {
            $dom2 = new DomDocument();
            $dom2->loadXML($feed);
            $xp2 = new DomXPath($dom2);
            $xp2->registerNamespace("des", "http://riddl.org/ns/description/1.0");
            $xpQuery2 = "/des:description/des:message[@name = \"" . $entry->getAttribute("in") . "\"]/des:parameter[@name]";
            $message = $xp->query($xpQuery2);
            $link = $this->rootURI . $resourcePath . "?";// . $message->item(0)->nodeValue;
echo "\n\n\n//QUERY: ". $xpQuery2;
print_r($message);
echo "\n\n\n//MESSAGE: ". $message->item(0)->nodeValue;
          }
        } else {
          $link = $this->rootURI . $resourcePath . "?method=" . $entry->tagName . "&message=" . $entry->getAttribute("in");
        }
        $this->generateTreeEntry($parentIndex, $name, $link);
      }
    }
  }


  private function includeScript() {
    echo "<script type=\"text/javascript\">\n";
    echo <<<DEADBEEF
function Node(id, pid, name, url, title, target, icon, iconOpen, open) {
DEADBEEF;
    echo "</script>\n";
  }
}

?>