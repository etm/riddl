<?
  class RiddlHeader {
    private $name;
    private $value;

    function __construct($name,$value) {
      $this->name = $name;
      $this->value = $value;
    }
    function name() { return $this->name; }
    function value() { return $this->value; }
  }
?>
