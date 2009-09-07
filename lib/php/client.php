<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/parameter.php");
  require_once($includes . "/header.php");
  require_once($includes . "/httpgenerator.php");
  require_once($includes . "/httpparser.php");
  require_once($includes . "/clientresponse.php");

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

    function get($what) { return $this->request("get",$what); }
    function post($what) { return $this->request("post",$what); }
    function put($what) { return $this->request("put",$what); }
    function delete($what) { return $this->request("delete",$what); }
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
      return $this->riddl_it(strtoupper($type),$params,$headers);
    }

    private function riddl_it($type,$params,$headers) {
      $urlp = parse_url($this->base . $this->resource);
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

      if (is_null($this->debug)) {
        $sock = fsockopen($urlp['host'], $urlp['port'], $errno, $errstr, 30);
        if (!$sock) die("$errstr ($errno)\n");
      } else {  
        $sock = fopen($this->debug,'w');
      }

      fwrite($sock, $type . " " . trim($urlp['path']) . " HTTP/1.1" . $this->EOL);
      fwrite($sock, "Host: " . $urlp['host'] . $this->EOL);
      $g = new RiddlHttpGenerator($headers,$params,$sock,'socket');
      $g->generate();

      $headers = '';
      $body = tmpfile();
      if (is_null($this->debug)) {
        while ($str = trim(fgets($sock, 4096)))
          $headers .= "$str\n";
        while (!feof($sock))
          fwrite($body,fgets($sock, 4096));
      }  
      fclose($sock);
      rewind($body);

      preg_match("/HTTP\/[\d\.]+\s+(\d+)/i", $headers, $matches);
      $code = $matches[1];
      preg_match("/Content-Disposition: (.*)/i", $headers, $matches);
      $content_disposition = $matches[1];
      preg_match("/Content-Type: (.*)/i", $headers, $matches);
      $content_type = $matches[1];
      preg_match("/Content-ID: (.*)/i", $headers, $matches);
      $content_id = $matches[1];
      preg_match("/Content-Length: (.*)/i", $headers, $matches);
      $content_length = $matches[1];
      preg_match("/Riddl-Type: (.*)/i", $headers, $matches);
      $riddl_type = $matches[1];

      $ret = new RiddlHttpParser(NULL,$body,$content_type,$content_length,$content_disposition,$content_id,$riddl_type);
      return new RiddlClientResponse($code,$ret->params());
    }
  }

?>
