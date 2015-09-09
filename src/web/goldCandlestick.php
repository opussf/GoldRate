<?php
#
# https://google-developers.appspot.com/chart/interactive/docs/gallery/candlestickchart
#

error_reporting(0);
require_once('graphSizes.php');
require_once('parseGRCSV.php');

if (array_key_exists( "size", $_GET )) {
	$size = $_GET["size"];
} else {
	$size = "normal";
}
$rfIn = stripslashes($_GET["rf"]);

# Read CSV file
$factionData = parseGRCSV($rfIn);

$divStyle = sprintf("width: %spx; height: %spx", $graphSizes[$size]["x"], $graphSizes[$size]["y"]);
$ocmm = array();  # OpenCloseMinMax

foreach( $factionData as $rf => $dataPoints) {
	foreach( $dataPoints as $ts => $val) {
		$beginOfDay = strtotime("midnight", $ts);
		if ($ocmm[$beginOfDay]) {
			$ocmm[$beginOfDay]["min"] = min($ocmm[$beginOfDay]["min"], $val);
			$ocmm[$beginOfDay]["max"] = max($ocmm[$beginOfDay]["max"], $val);
			if ($ts < $ocmm[$beginOfDay]["minTS"]) {
				$ocmm[$beginOfDay]["minTS"] = $ts;
				$ocmm[$beginOfDay]["open"] = $val;
			}
			if ($ts > $ocmm[$beginOfDay]["maxTS"]) {
				$ocmm[$beginOfDay]["maxTS"] = $ts;
				$ocmm[$beginOfDay]["close"] = $val;
			}
		} else {
			$ocmm[$beginOfDay] = array( "open" => $val, "close" => $val, "min" => $val, "max" => $val , "minTS" => $ts, "maxTS" => $ts );
		}
	}
}

#$print_r($ocmm);
# create the JpGraph expected data array

$datax = array_keys($ocmm);
sort($datax);
$datay = array();
foreach( $datax as $ts) {
	array_push($datay, $ocmm[$ts]["open"], $ocmm[$ts]["close"], $ocmm[$ts]["min"], $ocmm[$ts]["max"]);
}
?>
<html>
	<head>
		<script type="text/javascript" src="https://www.google.com/jsapi"></script>
		<script type="text/javascript">
	google.load("visualization", "1", {packages:["corechart"]});
	google.setOnLoadCallback(drawChart);
	function drawChart() {
		var data = google.visualization.arrayToDataTable([
<?php
	$googleData = array();
	for( $i = 0; $i < count($datax); $i++) {
		$ts = $datax[$i];
		array_push($googleData, sprintf("[new Date('%s'), %s, %s, %s, %s]", 
			date("Y-m-d\T00:00:00", $ts), #2015, 8, 3 (month is 0 based?????
			$ocmm[$ts]['min'],
			$ocmm[$ts]['open'],
			$ocmm[$ts]['close'],
			$ocmm[$ts]['max']
		));
		#array_push($googleData, "['".date("Y-m-d", $ts)."', ".$ocmm[$ts]["min"].",".$ocmm[$ts]["open"].",".$ocmm[$ts]["close"].",".$ocmm[$ts]["max"]."]");
	}
	print_r(implode(",\n", $googleData)."\n");
?>
		], true); // Treat first row as data as well.

		var options = {
			bar: { groupWidth: '100%' }, // Remove space between bars.
			title: "<?=$rf ?>",
			titlePosition: 'in',
			legend:'none',
			hAxis: {
				format: 'MMM d, y',
				textPosition: 'out', 
				maxValue: new Date('<? echo date("Y-m-d\T00:00:00")?>'),
			},
			candlestick: {
				fallingColor: { strokeWidth: 0, fill: '#a52714' }, // red
				risingColor: { strokeWidth: 0, fill: '#0f9d58' }   // green
			},
		};

		var chart = new google.visualization.CandlestickChart(document.getElementById('chart_div'));

		chart.draw(data, options);
	}
		</script>
	</head>
	<body>
		<div id="chart_div" style="<?=$divStyle ?>"></div> 
	</body>
</html>

