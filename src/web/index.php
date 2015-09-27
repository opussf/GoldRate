<?php
require_once("parseGRCSV.php");

if ($_GET["period"]) {
	$period = $_GET['period'];
}

$factionData = parseGRCSV("",$period);
$rfSizes = array();
foreach( $factionData as $rf => $dataPoints ) {
	$rfSizes[$rf] = count($dataPoints);
}
arsort($rfSizes);

$graphTypeArray = array( "goldCandlestick" => "goldCandlestick",
		"goldArea" => "goldArea"
);
$type = "goldArea";
if ($_GET["type"]) {
	$type = $graphTypeArray[$_GET['type']];
}


print <<<END
<html>
<head>
<title>Gold Graphs</title>
<meta http-equiv="refresh" content="300">
<link type='text/css' href="GR.css" rel="stylesheet"/>
</head>
<body>
<div class="main">
<div class="head">
<ul>
<li><a href="index.php?period=1d&type=$type">1d</a></li>
<li><a href="index.php?period=3d&type=$type">3d</a></li>
<li><a href="index.php?period=1w&type=$type">1w</a></li>
<li><a href="index.php?period=2w&type=$type">2w</a></li>
<li><a href="index.php?period=1m&type=$type">1m</a></li>
<li><a href="index.php?period=2m&type=$type">2m</a></li>
<li><a href="index.php?type=$type">all</a></li>
<li><a href="?period=$period&type=goldCandlestick">CandleStick</a></li>
<li><a href="?period=$period&type=goldArea">Area</a></li>
</ul>
</div>
END;
$count = 1;
foreach( $rfSizes as $rf => $size ) {
	#print("$rf => $size\n<br/>\n");
	print <<<END
<div class="fr" style="display: inline-block; width:310">
<a target="_blank" href="$type.php?rf=$rf&period=$period">$count -- $rf (${rfSizes[$rf]})</a>
<iframe src="$type.php?rf=$rf&size=micro&period=$period" width="100%" height="210" scrolling="no" frameborder="0"></iframe>
<!--
<div id="$count">
	<object type="text/html" data="goldCandlestick.php?rf=$rf&size=small" width="100%" height="202"/>
</div>
<a href="goldStockGraph.php?rf=$rf"><img border="1" src="goldStockGraph.php?rf=$rf&size=small"/></a>
-->
<!--
<br/><hr/><br/>
-->
</div>  <!-- fr -->
END;
$count+=1;
}
print <<<END
<img src="goldGraph.php?period=$period"/>
END;
?>
<br/>
<a href="GR.csv">Raw CSV file</a>
</div> <!-- main -->
</body>
</html>
