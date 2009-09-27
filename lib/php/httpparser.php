<?
  class RiddlHttpParser {
    private $params;
    private $MULTIPART_CONTENT_TYPES = array(
      #{{{
      'multipart/form-data',
      'multipart/related',
      'multipart/mixed'
      #}}}
    );
    private $FORM_CONTENT_TYPES = array(
      #{{{
      NULL,
      'application/x-www-form-urlencoded'
      #}}}
    );
    private $EOL = "\r\n";
    private $D = '&;';

    function params(){
      return $this->params;
    }  

    private function parse_content($input,$ctype,$content_length,$content_disposition,$content_id,$riddl_type) {
      #{{{
      if ($content_length == 0) return;
      if ($riddl_type == 'simple') $ctype = NULL;
      $mf = preg_match("/ filename=\"?([^\";]*)\"?/i", $content_disposition, $matchesf); # TODO debug
      $mn = preg_match("/ filename=\"?([^\";]*)\"?/i", $content_disposition, $matchesn); # TODO debug
      $filename = $matchesf[1];
      $name = $mn ? $matchesn[1] : $content_id;

      if (!is_null($ctype) || !is_null($filename)) {
        $body = tmpfile(); # TODO debug
      } else {
        $body = '';
      }

      $bufsize = 16384;

      while ($content_length > 0) {
        $c = fread($input,$bufsize < $content_length ? $bufsize : $content_length);
        if (!$c)
          throw new Exception("bad content body");
        $this->write_body($body,$c);
        $content_length -= strlen($c);
      }

      $this->add_to_params($name,$body,$filename,$ctype,NULL);
      #}}}
    }

    private function parse_multipart($input,$content_type,$content_length) {
      #{{{
      preg_match("/\Amultipart\/.*boundary=\"?([^\";,]+)\"?/",$content_type,$matches);
      $boundary = '--' . $matches[1];

      $boundary_size = strlen($boundary) + strlen($this->EOL);
      $content_length -= $boundary_size;
      $status = fread($input,$boundary_size);
      if (!$status == $boundary . $this->EOL)
        throw new Exception("bad content body");

      $rx = "/(?:" . $this->EOL . ")?" . preg_quote($boundary) . "(" . $this->EOL . "|--)/";

      $buf = '';
      $bufsize = 16384;
      while (true) {
        $head = NULL;
        $body = '';
        $filename = NULL; $ctype = NULL; $name = NULL;

        while (!($head && preg_match($rx,$buf))) {
          if (!$head && $i = strpos($buf,$this->EOL . $this->EOL)) {
            $head = substr($buf,0,$i+2); # First \r\n
            $buf = substr($buf,$i+4); # Second \r\n
            
            $mf = preg_match("/Content-Disposition:.* filename=\"?([^\";]*)\"?/i", $head, $matches);
            $filename = $mf ? $matches[1] : NULL;
            $mc = preg_match("/Content-Type: (.*)" . $this->EOL . "/i", $head, $matches);
            $ctype = $mc ? $matches[1] : NULL;
            $md = preg_match("/Content-Disposition:.*\s+name=\"?([^\";]*)\"?/i", $head, $matchesd);
            $mi = preg_match("/Content-ID:\s*([^" . $this->EOL . "]*)/i", $head, $matchesi);

            $name = $md ? $matchesd[1] : ($mi ? $matchesi[1] : 'bullshit');

            if ($ctype || $filename)
              $body = tmpfile();

            continue;
          }

          # Save the read body part.
          if ($head && ($boundary_size+4 < strlen($buf))) {
            $this->write_body($body,substr($buf,0, strlen($buf) - ($boundary_size+4)));
            $buf = substr($buf,$boundary_size+4);
          }

          $c = fread($input,$bufsize < $content_length ? $bufsize : $content_length);
          if (!$c)
            throw new Exception("bad content body");
          $buf .= $c;
          $content_length -= strlen($c);
        }

        # Save the rest.
        preg_match($rx,$buf,$matches);
        if ($i = strpos($buf,$matches[0])) {
          $this->write_body(&$body,substr($buf,0,$i));
          $buf = substr($buf, $i + $boundary_size+2);
          if ($matches[0] == "--")
            $content_length = -1;
        }
        $this->add_to_params($name,$body,$filename,$ctype,$head);

        if (!$buf || $content_length == -1)
          break;
      }
      #}}}
    }

    private function parse_nested_query($qs, $type) {
      #{{{
      if ($qs) {
        $what = preg_split("/[" . $this->D . "] */",$qs);
        foreach ($what as $p) {
          $p = urldecode($p);
          $p = preg_split('/=/',$p,2);
          array_push($this->params,new RiddlParameterSimple($p[0],$p[1],$type));
        }
      }  
      #}}}
    }

    private function write_body($body,$what) {
      #{{{
      if (is_resource($body))
        fwrite($body,$what);
      if (is_string($body))
        $body .= $what;
      #}}}
    }

    private function add_to_params($name,$body,$filename,$ctype,$head) {
      #{{{
      if (!is_null($filename) && $filename == '') {
        # filename is blank which means no file has been selected
      } elseif ($filename && $ctype) {
        # Take the basename of the upload's original filename.
        # This handles the full Windows paths given by Internet Explorer
        # (and perhaps other broken user agents) without affecting
        # those which give the lone filename.
        preg_match("/^(?:.*[:\\\/])?(.*)/m",$filename,$matches);
        $filename = $matches[1];
        array_push($this->params,new RiddlParameterComplex($name,$ctype,$body,$filename,$head));
      } elseif (!$filename && $ctype) {
        # Generic multipart cases, not coming from a form
        array_push($this->params,new RiddlParameterComplex($name,$ctype,$body,NULL,$head));
      } else {
        array_push($this->params,new RiddlParameterSimple($name,$body,'body'));
      }
      #}}}
    }

    function __construct($query_string,$input,$content_type,$content_length,$content_disposition,$content_id,$riddl_type) {
      #{{{
      $this->params = array();

      $ct = preg_split("/\s*[;,]\s*/",$content_type,2);
      $media_type = strtolower($ct[0]);
      $params = array();
      $this->parse_nested_query($query_string,'query');
      if (array_search($media_type,$this->MULTIPART_CONTENT_TYPES)) {
        $this->parse_multipart($input,$content_type,intval($content_length));
      } elseif (array_search($media_type,$this->FORM_CONTENT_TYPES)) {
        # sub is a fix for Safari Ajax postings that always append \0
        $contents = '';
        while (!feof($input)) {
          $contents .= fread($input, 8192);
        }
        $this->parse_nested_query(preg_replace("/\\0\\z/", '', $contents),'body');
      } else {
        $this->parse_content($input,$content_type,intval($content_length),$content_disposition ? $content_disposition : '',$content_id ? $content_id : '',$riddl_type ? $riddl_type : '');
      }
      #}}}
    }
  }
?>
