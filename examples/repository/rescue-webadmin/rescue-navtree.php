<?php
class RESCUENavTree {
  private $id;
  private $rootURI;
  private $target;
  private $arrayIndex = 0;
  private $description = NULL;
  private $riddlClient = NULL;

  function __construct($id, $uri, $target) {
    $this->id = $id;
    $this->rootURI = $uri;
    $this->target = $target;
    $this->riddlClient = new RiddlClient($this->rootURI);

    $return = $this->riddlClient->request("RIDDL", $what);
    $params = $return->parameters();
//    print $return->status();
    $feed = fread($params[0]->value(), $params[0]->size());
    $this->description = new DomDocument();
    $this->description->loadXML($feed);

  }

  function generate() {
    $this->generateStyle();
    $this->includeScript();
    echo "<div class=\"" . $this->id . "\">\n";
    echo "<script type=\"text/javascript\">\n";
    echo "var " . $this->id . " = new dTree('". $this->id . "');\n";
    echo $this->id . ".config.target = \"" . $this->target . "\";\n";

    $dom = $this->getFeed("groups");
    $entries = $dom->getElementsByTagName("entry");
    // Create a nodes named RESCUE and groups
    $this->generateTreeEntry(-1, "RESCUE");
    $this->addSupportedMessages(" ", 0);
    $this->generateTreeEntry(0, "groups");
    $this->generateReposTree("groups/", 2);

    echo "document.write(" . $this->id . ");\n";
    echo "</script>\n";
    echo "</div>\n";
  }


  private function generateReposTree($resourcePath, $parentIndex) {
    $dom = $this->getFeed($resourcePath, $returnParameterName);
    if($dom == null) return;
    $entries = $dom->getElementsByTagName("entry");
    $this->addSupportedMessages($resourcePath, $parentIndex);
    foreach($entries as $entry) {
      $this->generateTreeEntry($parentIndex, $entry->getElementsByTagName("id")->item(0)->nodeValue);
      $this->generateReposTree($resourcePath . $entry->getElementsByTagName("id")->item(0)->nodeValue . "/", $this->arrayIndex-1);
    }
   }

  private function addSupportedMessages($resourcePath, $parentIndex) {
    $i = 0;
    $resourceLevel = substr_count($resourcePath, "/");
    $xpQuery = "/des:description/des:resource";
    while($i < $resourceLevel) {
      $xpQuery .= "/des:resource";
      $i++;
    }
    $xpQuery .= "/*";

    $xp = new DomXPath($this->description);
    $xp->registerNamespace("des", "http://riddl.org/ns/description/1.0");
    $entries = $xp->query($xpQuery); 
    foreach($entries as $entry) {
      $name = "";
      if($entry->tagName != "resource") {
        $children = $entry->childNodes;
        foreach ($children as $child) {
          if($child->tagName == "ann:label") $name = $child->nodeValue;
        }
        if($name == "") {
          if(($entry->getAttribute("in") == "*") && ($entry->hasAttribute("out") == true)) {
            $name = strtoupper($entry->tagName) . " (Out: " . $entry->getAttribute("out") . ")";
          } elseif(($entry->getAttribute("in") != "*") && ($entry->hasAttribute("out") == false)) {
            $name = strtoupper($entry->tagName) . " (In: " . $entry->getAttribute("in") . ")";
          } elseif(($entry->getAttribute("in") == "*") && ($entry->hasAttribute("out") == false)) {
            $name = strtoupper($entry->tagName);
          } else {
            $name = strtoupper($entry->tagName) . " (" . $entry->getAttribute("in") . " -> " . $entry->getAttribute("out") .")";
          }
        }
        if($entry->tagName == "get") {
          if($entry->getAttribute("in") == "*") {
            $link = $this->rootURI . $resourcePath;
          } else {
            $xpQuery = "/des:description/des:message[@name = \"" . $entry->getAttribute("in") . "\"]/des:parameter[@name]";
            $message = $xp->query($xpQuery);
            $link = $this->rootURI . $resourcePath . "?";
            foreach($message as $m) {
              $link .= $m->getAttribute('name') . "&";
            }
          }
        } else {
          $link = "create-form-by-message.php" . "?resource=". $resourcePath . "&method=";
          if($entry->hasAttribute("method") == true) {
            $link .= $entry->getAttribute("method");
          } else {
            $link .= $entry->tagName;
          }
          $link .= "&message=" . $entry->getAttribute("in");
        }
        $this->generateTreeEntry($parentIndex, $name, $link);
      }
    }
  }

  private function getFeed($resourcePath) {
    $this->riddlClient->resource($resourcePath);
    $return = $this->riddlClient->request("GET", $what);
    $params = $return->parameters();
    $feed = fread($params[0]->value(), $params[0]->size());
    $dom = new DomDocument();
    $dom->loadXML($feed);
    return $dom;
  }


  private function generateTreeEntry($parentIndex, $name, $link = "") {
    echo $this->id . ".add(" . ($this->arrayIndex) . "," . $parentIndex . ",'" . $name . "','" . $link . "');\n";
    $this->arrayIndex++;
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


  private function includeScript() {
    echo "<script type=\"text/javascript\">\n";
    echo <<<DEADBEEF
function Node(id, pid, name, url, title, target, icon, iconOpen, open) {
DEADBEEF;
    echo "</script>\n";
  }
}

?>