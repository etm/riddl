<?
  class Riddl_HttpGenerator {

    private $BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata";
    private $EOL = "\r\n";
    private $BUFFERSIZE = 8192;

    function __construct($params,$headers,$sock) {
      $this->sock = $sock;
      $this->params = $params;
      $this->headers = $headers;
    }

    function generate() {
      if (is_array($this->params) && count($this->params) == 1) {
        $this->body($this->params[0]);
      } elseif (is_a($this->params,'RiddlParameterSimple') || is_a($this->params,'RiddlParameterComplex')) {
        $this->body($this->params);
      } elseif (is_array($this->params) && count($this->params) > 1)
        $this->multipart();
      }
      fwrite($this->sock, $this->EOL);
    end

    private function body($r) {
      if (is_a($r,'RiddlParameterSimple')) {
        fwrite($this->sock, "Content-type: text/riddl-data" . $this->EOL);
        fwrite($this->sock, "Content-length: " . $r->size . $this->EOL);
        fwrite($this->sock, $this->EOL);
        fwrite($this->sock, $r->value);
        fwrite($this->sock, $this->EOL);
      } elseif (is_a($this->params,'RiddlParameterComplex')) {
        fwrite($this->sock, "Content-type: " . $r->mimetype . $this->EOL);
        fwrite($this->sock, "Content-length: " . $r->size . $this->EOL);
        if (is_null($r.filename)) {
          fwrite($this->sock, "Content-ID: " . $r->name . $this->EOL);
        } else {
          fwrite($this->sock, "Content-Disposition: riddl-data; name=\"" . $r->name . "\"; filename=\"" . $r->filename . "\"" . $this->EOL);
        }
        fwrite($this->sock, $this->EOL);
        if (is_resource($r->value) && (get_resource_type($r->value) == 'file')) {
          $this->copy_content($r->value);
        } elseif (is_buffer($r->value)) {
          fwrite($this->sock, $r->value);
        }
        fwrite($this->sock, $this->EOL);
      }  
    }

    private function copy_content($handle) {
      while (!feof($handle)) {
        fwrite($this->sock, fread($handle, $this->BUFFERSIZE));
      }
    }
    
    private function multipart($rs) {
      fwrite($this->sock, "Content-type: multipart/mixed; boundary=\"" . $this->BOUNDARY . "\"" . $this->EOL);
      fwrite($this->sock, $this->EOL);
      foreach($rs as $r) {
        if (is_a($r,'RiddlParameterSimple')) {
          fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($this->sock, "Content-Disposition: riddl-data; name=\"" . $r->name . "\"" . $this->EOL);
          fwrite($this->sock, $this->EOL);
          fwrite($this->sock, $r->value);
          fwrite($this->sock, $this->EOL);
        } elseif (is_a($this->params,'RiddlParameterComplex')) {
          fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
          fwrite($this->sock, "Content-Disposition: riddl-data; name=\"");
          if (is_null($r->filename)) {
            fwrite($this->sock, $this->EOL);
          } else {
            fwrite($this->sock, "; filename=\"" . $r->filename . "\"" . $this->EOL);
          }
          fwrite($this->sock, "Content-Transfer-Encoding: binary" . $this->EOL);
          fwrite($this->sock, "Content-type: " . $r->mimetype . $this->EOL);
          fwrite($this->sock, $this->EOL);
          if (is_resource($r->value) && (get_resource_type($r->value) == 'file')) {
            $this->copy_content($r->value);
          } elseif (is_buffer($r->value)) {
            fwrite($this->sock, $r->value);
          }
          fwrite($this->sock, $this->EOL);
          fwrite($this->sock, "Content-type: " . $r->mimetype . $this->EOL);
          fwrite($this->sock, "Content-length: " . $r->size . $this->EOL);
          if (is_null($r.filename)) {
            fwrite($this->sock, "Content-ID: " . $r->name . $this->EOL);
          } else {
            fwrite($this->sock, "Content-Disposition: riddl-data; name=\"" . $r->name . "\"; filename=\"" . $r->filename . "\"" . $this->EOL);
          }
          fwrite($this->sock, $this->EOL);
          if (is_resource($r->value) && (get_resource_type($r->value) == 'file')) {
            $this->copy_content($r->value);
          } elseif (is_buffer($r->value)) {
            fwrite($this->sock, $r->value);
          }
          fwrite($this->sock, $this->EOL);
        }  
      }
      fwrite($this->sock, "--" . $this->BOUNDARY . $this->EOL);
    }

  }
?>
