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
      }
      $this->critical_eol();
    }

    private function body($r) {
      if (is_a($r,'RiddlParameterSimple')) {
        $this->set_header("Content-type","text/riddl-data");
        $this->set_header("Content-length",$r->size());
        $this->critical_eol();
        fwrite($this->sock, $r->value());
        $this->critical_eol();
      } elseif (is_a($r,'RiddlParameterComplex')) {
        $this->set_header("Content-type",$r->mimetype());
        $this->set_header("Content-length",$r->size());
        if (is_null($r->filename())) {
          $this->set_header("Content-ID",$r->name());
        } else {
          $this->set_header("Content-Disposition","riddl-data; name=\"" . $r->name() . "\"; filename=\"" . $r->filename() . "\"");
        }
        $this->critical_eol();
        if (is_resource($r->value()) && (get_resource_type($r->value()) == 'file')) {
          $this->copy_content($r->value());
        } elseif (is_string($r->value())) {
          fwrite($this->sock, $r->value());
        }
        $this->critical_eol();
      }  
    }

    private function multipart() {
      $this->set_header("Content-type","multipart/mixed; boundary=\"" . $this->BOUNDARY . "\"");
      $this->critical_eol();
      foreach($this->params as $r) {
        if (is_a($r,'RiddlParameterSimple')) {
          fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($this->sock, "Content-Disposition: riddl-data; name=\"" . $r->name() . "\"" . $this->EOL);
          fwrite($this->sock, $this->EOL);
          fwrite($this->sock, $r->value());
          fwrite($this->sock, $this->EOL);
        } elseif (is_a($r,'RiddlParameterComplex')) {
          fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($this->sock, "Content-Disposition: riddl-data; name=\"" . $r->name() . "\"");
          if (is_null($r->filename())) {
            fwrite($this->sock, $this->EOL);
          } else {
            fwrite($this->sock, "; filename=\"" . $r->filename() . "\"" . $this->EOL);
          }
          fwrite($this->sock, "Content-Transfer-Encoding: binary" . $this->EOL);
          fwrite($this->sock, "Content-type: " . $r->mimetype() . $this->EOL);
          fwrite($this->sock, $this->EOL);
          if (is_resource($r->value()) && (get_resource_type($r->value()) == 'file')) {
            $this->copy_content($r->value());
          } elseif (is_string($r->value())) {
            fwrite($this->sock, $r->value());
          }
          fwrite($this->sock, $this->EOL);
        }  
      }
      fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
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

    private function copy_content($handle) {
      while (!feof($handle)) {
        fwrite($this->sock, fread($handle, $this->BUFFERSIZE));
      }
    }
    
  }
?>
