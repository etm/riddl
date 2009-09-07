<?
  class RiddlHttpGenerator {
    private $BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata";
    private $EOL = "\r\n";
    private $BUFFERSIZE = 8192;

    function __construct($headers,$params,$sock,$type) {
      $this->headers = $headers;
      $this->params = $params;
      $this->sock = $sock;
      $this->type = $type;
    }

    function generate() {
      # set all headers
      foreach ($this->headers as $h) {
        $this->set_header($h->name(),$h->value());
      }
      # generate content
      if (is_array($this->params) && count($this->params) == 1) {
        $this->body($this->params[0]);
      } elseif (is_a($this->params,'RiddlParameterSimple') || is_a($this->params,'RiddlParameterComplex')) {
        $this->body($this->params);
      } elseif (is_array($this->params) && count($this->params) > 1) {
        $this->multipart();
      } else {
        $this->set_header("Content-length","0");
      }
      $this->critical_eol();
    }

    private function body($r) {
      if (is_a($r,'RiddlParameterSimple')) {
        $this->set_header("Content-Type","text/plain");
        $this->set_header("Riddl-Type","simple");
        $this->set_header("Content-ID",$r->name());
        $this->set_header("Content-length",$r->size());
        $this->critical_eol();
        fwrite($this->sock, $r->value());
        $this->critical_eol();
      } elseif (is_a($r,'RiddlParameterComplex')) {
        $this->set_header("Content-Type",$r->mimetype());
        $this->set_header("Riddl-Type","complex");
        $this->set_header("Content-Length",$r->size());
        if (is_null($r->filename())) {
          $this->set_header("Content-ID",$r->name());
        } else {
          $this->set_header("Content-Disposition","riddl-data; name=\"" . $r->name() . "\"; filename=\"" . $r->filename() . "\"");
        }
        $this->critical_eol();
        if (is_resource($r->value()) && (get_resource_type($r->value()) == 'file')) {
          $this->copy_content($r->value(),$this->sock);
        } elseif (is_string($r->value())) {
          fwrite($this->sock, $r->value());
        }
        $this->critical_eol();
      }  
    }

    private function multipart() {
      $this->set_header("Content-type","multipart/mixed; boundary=\"" . $this->BOUNDARY . "\"");
      $ret = tmpfile();
      foreach($this->params as $r) {
        if (is_a($r,'RiddlParameterSimple')) {
          fwrite($ret, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($ret, "Riddl-Type: simple" . $this->EOL);
          fwrite($ret, "Content-Disposition: riddl-data; name=\"" . $r->name() . "\"" . $this->EOL);
          fwrite($ret, $this->EOL);
          fwrite($ret, $r->value());
          fwrite($ret, $this->EOL);
        } elseif (is_a($r,'RiddlParameterComplex')) {
          fwrite($ret, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($ret, "Riddl-Type: complex" . $this->EOL);
          fwrite($ret, "Content-Disposition: riddl-data; name=\"" . $r->name() . "\"");
          if (is_null($r->filename())) {
            fwrite($ret, $this->EOL);
          } else {
            fwrite($ret, "; filename=\"" . $r->filename() . "\"" . $this->EOL);
          }
          fwrite($ret, "Content-Transfer-Encoding: binary" . $this->EOL);
          fwrite($ret, "Content-Type: " . $r->mimetype() . $this->EOL);
          fwrite($ret, $this->EOL);
          if (is_resource($r->value()) && (get_resource_type($r->value()) == 'file')) {
            $this->copy_content($r->value(),$ret);
          } elseif (is_string($r->value())) {
            fwrite($ret, $r->value());
          }
          fwrite($ret, $this->EOL);
        }  
      }
      fwrite($ret, "--" . $this->BOUNDARY . $this->EOL);
      $this->set_header("Content-length",ftell($ret));

      $this->critical_eol();
      rewind($ret);
      $this->copy_content($ret,$this->sock);
    }

    private function critical_eol() {
      if ($this->type == 'socket') {
        fwrite($this->sock, $this->EOL);
      }  
    }  
    private function set_header($name,$value) {
      if ($this->type == 'header') {
        header("$name: $value");
      }
      if ($this->type == 'socket') {
        fwrite($this->sock, "$name: $value" . $this->EOL);
      }
    }

    private function copy_content($handle,$ret) {
      while (!feof($handle)) {
        fwrite($ret, fread($handle, $this->BUFFERSIZE));
      }
    }
    
  }
?>
