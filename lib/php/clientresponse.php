<?
  class RiddlClientResponse {
    private $status;
    private $parameters;

    function __construct($status,$parameters) {
      $this->status = $status;
      $this->parameters = $parameters;
    }
    function status() { return $this->status; }
    function parameters() { return $this->parameters; }
  }
?>
