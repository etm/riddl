<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/parameter.php");
  require_once($includes . "/header.php");
  require_once($includes . "/httpgenerator.php");

  class RiddlClient {
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
      $this->riddl_it($params,$headers);
    }

    private function riddl_it() {
      if (is_null($this->debug)) {
        $g = new RiddlHttpGenerator($this->headers,$this->params,fopen('php://output','w'),'header');
      } else {
        $g = new RiddlHttpGenerator($this->headers,$this->params,fopen($this->debug,'w'),'socket');
      }
      $g->generate();
      exit;
    }
  }

#  $sock = fsockopen("ssl://secure.example.com", 443, $errno, $errstr, 30);
#  if (!$sock) die("$errstr ($errno)\n");
#
#  $data = "foo=" . urlencode("Value for Foo") . "&bar=" . urlencode("Value for Bar");
#  fwrite($sock, "POST /form_action.php HTTP/1.0\r\n");
#  fwrite($sock, "Host: secure.example.com\r\n");
#  fwrite($sock, "Content-type: application/x-www-form-urlencoded\r\n");
#  fwrite($sock, "Content-length: " . strlen($data) . "\r\n");
#  fwrite($sock, "Accept: */*\r\n");
#  fwrite($sock, "\r\n");
#  fwrite($sock, "$data\r\n");
#  fwrite($sock, "\r\n");
#
#  $headers = "";
#  while ($str = trim(fgets($sock, 4096)))
#  $headers .= "$str\n";
#
#  echo "\n";
#  $body = "";
#  while (!feof($sock))
#  $body .= fgets($sock, 4096);
#  fclose($sock);

?>
