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
$factionData = parseGRCSV($rfIn, $_GET["period"]);

$divStyle = sprintf("width: %spx; height: %spx", $graphSizes[$size]["x"], $graphSizes[$size]["y"]);

$datax = array_keys( $factionData[$rfIn] );
$datay = array_values( $factionData[$rfIn] );

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
		array_push($googleData, sprintf("[new Date('%s'), %s]", 
			date("Y-m-d\TH:i:s", $ts), #2015, 8, 3 (month is 0 based?????
			$datay[$i]
		));
		#array_push($googleData, "['".date("Y-m-d", $ts)."', ".$ocmm[$ts]["min"].",".$ocmm[$ts]["open"].",".$ocmm[$ts]["close"].",".$ocmm[$ts]["max"]."]");
	}
	print_r(implode(",\n", $googleData)."\n");
?>
		], true); // Treat first row as data as well.

		var options = {
			is3D: true,
			bar: { groupWidth: '100%' }, // Remove space between bars.
			title: "<?=$rfIn ?>",
			titlePosition: 'in',
			legend: 'none',
			hAxis: {
				format: 'MMM d, y',
				textPosition: 'out', 
				maxValue: new Date('<? echo date("Y-m-d\TH:i:s")?>'),
			},
			vAxis: {
				title: 'Gold'
			},
			seriesType: 'area',
			trendlines: { 0: {
				type: 'polynomial',
				degree: 3,
				visibleInLegend: true,},
			},
		};

		var chart = new google.visualization.ComboChart(document.getElementById('chart_div'));

		chart.draw(data, options);
	}
		</script>
	</head>
	<body>
		<div id="chart_div" style="<?=$divStyle ?>"></div> 
	</body>
</html>

