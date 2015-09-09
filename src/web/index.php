<?php
require_once("parseGRCSV.php");

$factionData = parseGRCSV();
$rfSizes = array();
foreach( $factionData as $rf => $dataPoints ) {
	$rfSizes[$rf] = count($dataPoints);
}
arsort($rfSizes);

print <<<END
<html>
<head>
<title>Gold Graphs</title>
<meta http-equiv="refresh" content="300">
</head>
<body>
END;
$count = 1;
foreach( $rfSizes as $rf => $size ) {
	#print("$rf => $size\n<br/>\n");
	print <<<END
<a href="goldCandlestick.php?rf=$rf">$count -- $rf (${rfSizes[$rf]})</a>
<br/>
<iframe src="goldCandlestick.php?rf=$rf&size=small" width="100%" height="210" scrolling="no" frameborder="0"></iframe>
<!--
<div id="$count">
	<object type="text/html" data="goldCandlestick.php?rf=$rf&size=small" width="100%" height="202"/>
</div>
<a href="goldStockGraph.php?rf=$rf"><img border="1" src="goldStockGraph.php?rf=$rf&size=small"/></a>
-->
<br/><hr/><br/>
END;
$count+=1;
}
?>
<img src="goldGraph.php"/>
<br/>
<a href="GR.csv">Raw CSV file</a>
</body>
</html>
