<?php
  $includes = realpath(dirname(__FILE__));
  include_once($includes . "/rescue-navtree.php");
  include_once($includes . "/../../../lib/php/client.php");
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>RESCUE</title>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body>

<br /><br />

<b>Repository:</b><br /><br />

<?php 
//  $tree = new RESCUENavTree("myRepos", "http://sumatra.pri.univie.ac.at:9290:/", "Daten");
  $tree = new RESCUENavTree("myRepos", "http://localhost:9290/", "Daten");
  $tree->generate();
?>

</body>
</html>
