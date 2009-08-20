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

    private function parse_content($input,$ctype,$content_length,$content_disposition,$content_id) {
      #{{{
      if ($ctype == 'text/riddl-data') $ctype = NULL;
      $mf = preg_match("/ filename=\"?([^\";]*)\"?/ni", $content_disposition, $matchesf); # TODO debug
      $mn = preg_match("/ filename=\"?([^\";]*)\"?/ni", $content_disposition, $matchesn); # TODO debug
      $filename = $matchesf[1];
      $name = $mn ? $matchesn[1] : $content_id;

      if (!is_null($ctype) || !is_null($filename)) {
        $body = tmpfile(); # TODO debug
      } else {
        $body = '';
      }

      $bufsize = 16384;

      while ($content_length >= 0) {
        $c = fread($input,$bufsize < $content_length ? $bufsize : $content_length);
        if (!$c)
          throw new Exception("bad content body");
        $this->write_body($body,$c);
        $content_length -= strlen($c);
      }

      $this->add_to_params($name,$body,$filename,$ctype,NULL);
      #}}}
    }

    private function parse_multipart($input,$content_type,$content_length) { # TODO
      #{{{
      preg_match("/\Amultipart\/.*boundary=\"?([^\";,]+)\"?/n",$content_type,$matches);
      $boundary = "--" . $matches[1];

      $boundary_size = strlen($boundary) + strlen($this->EOL);
      $content_length -= $boundary_size;
      $status = fread($input,$boundary_size);
      if (!$status == $boundary . $this->EOL)
        throw new Exception("bad content body);

      $rx = "/(?:" . $this->EOL . ")?" . preg_quote($boundary) . "(" . $this->EOL . "|--)/n";

      $buf = "";
      $bufsize = 16384;
      while (true) {
        $head = NULL;
        $body = '';
        $filename = NULL; $ctype = NULL; $name = NULL;

        if (!($head && preg_match($rx,$buf))) {
          if (!$head && $i = strpos($buf,$this->EOL . $this->EOL)) {
            head = buf.slice!(0, i+2) # First \r\n # TODO substr
            buf.slice!(0, 2)          # Second \r\n

            filename = head[/Content-Disposition:.* filename="?([^\";]*)"?/ni, 1]
            ctype = head[/Content-Type: (.*)#{EOL}/ni, 1]
            name = head[/Content-Disposition:.*\s+name="?([^\";]*)"?/ni, 1] || head[/Content-ID:\s*([^#{EOL}]*)/ni, 1]

            if ctype || filename
              body = Parameter::Tempfile.new("RiddlMultipart")
              body.binmode  if body.respond_to?(:binmode)
            end

            continue;
          }

          # Save the read body part.
          if head && (boundary_size+4 < buf.size)
            body << buf.slice!(0, buf.size - (boundary_size+4))
          end

          c = input.read(bufsize < content_length ? bufsize : content_length)
          raise EOFError, "bad content body"  if c.nil? || c.empty?
          buf << c
          content_length -= c.size
        }

        # Save the rest.
        if i = buf.index(rx)
          body << buf.slice!(0, i)
          buf.slice!(0, boundary_size+2)
          content_length = -1  if $1 == "--"
        end

        add_to_params(name,body,filename,ctype,head)

        break if buf.empty? || content_length == -1
      }
      #}}}
    }

    private function parse_nested_query($qs, $type) {
      #{{{
      $what = preg_split("/[$D] */n",$qs || '');
      foreach ($what as $p) {
        $p = urldecode($p);
        $p = preg_split('/=/',$p,2);
        array_push($this->params,new RiddlParameterSimple($p[0],$p[1],$type));
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
      if ($filename == '') {
        # filename is blank which means no file has been selected
      } elseif ($filename && $ctype) {
        # Take the basename of the upload's original filename.
        # This handles the full Windows paths given by Internet Explorer
        # (and perhaps other broken user agents) without affecting
        # those which give the lone filename.
        preg_match("/^(?:.*[:\\\/])?(.*)/m",$filename,$matches);
        $filename = $matches[1];
        array_push($this->params,new RiddlParameterComplex.new($name,$ctype,$body,$filename,$head);
      } elseif (!$filename && $ctype) {
        # Generic multipart cases, not coming from a form
        array_push($this->params,new RiddlParameterComplex($name,$ctype,$body,NULL,$head));
      } else {
        array_push($this->params,new RiddlParameterSimple($name,$body,'body'));
      }
      #}}}
    }

    function __construct($query_string,$input,$content_type,$content_length,$content_disposition,$content_id) {
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
        $this->parse_nested_query(preg_replace("/\0\z/", '', $contents),'body');
      } else {
        $this->parse_content($input,$content_type,intval($content_length),$content_disposition||'',$content_id||'');
      }
      #}}}
    }
  }
?>
