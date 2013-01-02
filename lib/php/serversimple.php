<?
  $includes = realpath(dirname(__FILE__));
  require_once($includes . "/parameter.php");
  require_once($includes . "/header.php");
  require_once($includes . "/httpgenerator.php");
  require_once($includes . "/httpparser.php");

  class RiddlServerSimple {
    private $params;
    private $headers;
    private $debug;

    function __construct($debug=NULL) {
      $this->debug = $debug;
      $this->params = array();
      $this->headers = array();
      $rhp = new RiddlHttpParser($_SERVER["QUERY_STRING"],fopen('php://input','rb'),$_SERVER["CONTENT_TYPE"],$_SERVER["CONTENT_LENGTH"],$_SERVER["HTTP_CONTENT_DISPOSITION"],$_SERVER["HTTP_CONTENT_ID"],$_SERVER["HTTP_RIDDL_TYPE"]);
      $this->request = $rhp->params();
    }

    function request() {
      return $this->request;
    }
    function request_path() {
      return array_key_exists("PATH_INFO",$_SERVER) ? preg_replace('/\/+/','/',$_SERVER["PATH_INFO"]) : "/";
    }
    function request_method() {
      return $_SERVER["REQUEST_METHOD"];
    }

    function add($what) {
      if (is_array($what) && count($what) == 1 && (is_a($what[0],'RiddlParameterSimple') || is_a($what[0],'RiddlParameterComplex'))) {
        array_push($this->params,$what[0]);
      } elseif (is_array($what) && count($what) == 1 && is_a($what[0],'RiddlHeader')) {
        array_push($this->headers,$what[0]);
      } elseif (is_a($what,'RiddlParameterSimple') || is_a($what,'RiddlParameterComplex')) {
        array_push($this->params,$what);
      } elseif (is_a($what,'RiddlHeader')) {
        array_push($this->headers,$what);
      } elseif (is_array($what) && count($what) > 1) {
        foreach ($what as $w) {
          if (is_a($w,'RiddlParameterSimple') || is_a($w,'RiddlParameterComplex')) {
            array_push($this->params,$w);
          } elseif (is_a($w,'RiddlHeader')) {
            array_push($this->headers,$w);
          }
        }
      }
    }

    function riddl_it($status = 404) {
      if ($status == 200) {
        if (is_null($this->debug)) {
          $g = new RiddlHttpGenerator($this->headers,$this->params,fopen('php://output','w'),'header');
        } else {
          $g = new RiddlHttpGenerator($this->headers,$this->params,fopen($this->debug,'w'),'socket');
        }
        $g->generate('output');
      } else {
        header("HTTP/1.1 " . $status);
      }  
      exit;
    }
  }
?>
