<?
  class RiddlParameterSimple {
    private $name;
    private $value;
    private $type;
    private $size;

    function __construct($name,$value,$type='body') {
      $this->name = $name;
      $this->value = $value;
      $this->type = ($type == 'query' ? 'query' : 'body');
      $this->size = strlen($value);
    }
    function name() { return $this->name; }
    function value() { return $this->value; }
    function type() { return $this->type; }
    function size() { return $this->size; }
  }

  class RiddlParameterComplex {
    private $name;
    private $mimetype;
    private $value;
    private $type;
    private $size;
    private $filename = NULL;
    private $additional;

    function __construct($name,$mimetype,$value,$filename=NULL,$additional=array()) {
      $this->name = $name;
      $this->mimetype = $mimetype;
      $this->filename = $filename;
      $this->type = 'body';
      $this->additional = $additional;
      $this->value = $value;

      if (is_resource($this->value) && (!get_resource_type($this->value) == 'file' || !get_resource_type($this->value) == 'stream')) {
        throw new Exception('RiddlParameterComplex ' . $name . ' not a file.');
      }
      if (is_resource($this->value)) {
        fseek($this->value, 0, SEEK_END);
        $this->size = ftell($this->value);
        rewind($this->value);
      } else {
        $this->value = (string)$this->value;
        $this->size = strlen($this->value);
      }
    }
    function name() { return $this->name; }
    function mimetype() { return $this->mimetype; }
    function value() { return $this->value; }
    function type() { return $this->type; }
    function size() { return $this->size; }
    function filename() { return $this->filename; }
    function additional() { return $this->additional; }
  }
?>
