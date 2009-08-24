<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/parameter.php");
  require_once($includes . "/header.php");
  require_once($includes . "/httpgenerator.php");

  class RiddlClient {
    private $EOL = "\r\n";
    private $base;
    private $resource;
    private $debug;

    function __construct($base,$debug=NULL) {
      $this->base = $base;
      $this->resource = '';
      $this->debug = $debug;
    }

    function resource($path) {
      $this->resource = $path;
    }

    function get($what) { $this->request("get",$what); }
    function get($post) { $this->request("post",$what); }
    function get($put) { $this->request("put",$what); }
    function get($delete) { $this->request("delete",$what); }
    function request($type,$what) {
      $params = array();
      $headers = array();
      if (is_array($what)) {
        foreach ($what as $w) {
          if (is_a($w,'RiddlParameterSimple') || is_a($w,'RiddlParameterComplex')) {
            array_push($params,$w);
          } elseif (is_a($w,'RiddlHeader')) {
            array_push($headers,$w);
          }
        }
      }
      $this->riddl_it($type,$params,$headers);
    }

    private function riddl_it($type,$params,$headers) {
      if (is_null($this->debug)) {
        $urlp = parse_url($http->base . $http->resource);
        if (!isset($urlp['scheme']))
          $urlp['scheme'] = 'http';
        if (!isset($urlp['port'])) {
          switch ($urlp['scheme']) {
            case 'http':
              $urlp['port'] = 80;
              break;
            case 'https':
              $urlp['port'] = 443;
              break;
          }
        }

        $sock = fsockopen($urlp['scheme'] . '://' . $urlp['host'], $urlp['port'], $errno, $errstr, 30);
        if (!$sock) die("$errstr ($errno)\n");
        fwrite($sock, $type . " /" . $urlp['path'] . " HTTP/1.0" . $this->EOL);
        fwrite($sock, "Host: " . $urlp['host'] . $this->EOL);
        $g = new RiddlHttpGenerator($this->headers,$this->params,fopen($sock,'w'),'socket');

        $headers = "";
        while ($str = trim(fgets($sock, 4096)))
        $headers .= "$str\n";

        echo "\n";
        $body = "";
        while (!feof($sock))
        $body .= fgets($sock, 4096);
        fclose($sock);

      } else {
        $g = new RiddlHttpGenerator($this->headers,$this->params,fopen($this->debug,'w'),'socket');
      }
      $g->generate();
    }
  }

?>
