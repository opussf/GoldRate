<?php
error_reporting(0);
#error_reporting(E_ALL);
require_once('jpgraph/jpgraph.php');
require_once('jpgraph/jpgraph_scatter.php');
require_once('jpgraph/jpgraph_line.php');
require_once('jpgraph_utils.inc.php');
require_once('jpgraph/jpgraph_date.php');
require_once('jpgraph/jpgraph_plotline.php');
#require_once('jpgraph/jpgraph_log.php');
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
foreach( $factionData as $rf => $data ) {
	foreach( $data as $x => $y ) {
		if (isset($last[$rf])) {
			$factionData[$rf][intval($x)] = floatval($y - $last[$rf]);
		} else { $factionData[$rf][$x] = 0; }
		$last[$rf] = floatval($y);
	}
}

#init the jpgraph
$graph = new Graph( $graphSizes[$size]["x"], $graphSizes[$size]["y"] );
$graph->SetScale("datlin");
if ($rfIn == "") {
	$graph->img->SetMargin(60,315,40,80);
	$graph->tabtitle->Set("Gold Impulse");
} else {
	$graph->img->SetMargin(60,10,20,10);
	$yAverage = array_sum(array_values($factionData[$rfIn])) / count($factionData[$rfIn]);
	$graph->tabtitle->Set(sprintf("Gold Impluse - %s (%d) ave: %0.3g", $rfIn, count($factionData[$rfIn]), $yAverage));
}
$graph->SetShadow();
$graph->title->SetFont(FF_FONT1,FS_BOLD);

$cf = new ColorFactory();

$scatterPlots = array();
foreach( $factionData as $rf => $dataPoints ) {
	$scatterPlots[$rf]["datax"] = array_keys($dataPoints);
	$scatterPlots[$rf]["datay"] = array_values($dataPoints);
	$scatterPlots[$rf]["sp"] = new ScatterPlot($scatterPlots[$rf]["datay"], $scatterPlots[$rf]["datax"]);
	$scatterPlots[$rf]["sp"]->mark->SetType(MARK_FILLEDCIRCLE);
	$color = $cf->getColor();
	$scatterPlots[$rf]["sp"]->mark->SetFillColor($color);
	$scatterPlots[$rf]["sp"]->mark->SetWidth(4);
	$scatterPlots[$rf]["sp"]->link->Show();
	$scatterPlots[$rf]["sp"]->link->SetWeight(2);
	$scatterPlots[$rf]["sp"]->link->SetColor($color."@0.7");
	if ($rfIn == "") { $scatterPlots[$rf]["sp"]->SetLegend($rf); }
	$graph->Add($scatterPlots[$rf]["sp"]);

	$yAverage = array_sum($scatterPlots[$rf]["datay"]) / count($scatterPlots[$rf]["datay"]);

	#$lr = new LinearRegression( $scatterPlots[$rf]["datax"], $scatterPlots[$rf]["datay"] );
	#print($rf." = ".count($dataPoints)."<br/>");
	#list( $stderr, $corr, $deter ) = $lr->GetStat(); # stderr, correlation coefficient, determination coefficient
	#list( $a, $m ) = $lr->GetAB();
	#list( $xd, $yd ) = $lr->GetY( min($scatterPlots[$rf]["datax"]), time(), 3600 );
	#$scatterPlots[$rf]["lr"] = new LinePlot( $yd, $xd );
	#$scatterPlots[$rf]["lr"]->SetLegend(sprintf("%s\n(r^2=%0.3f, m=%0.3f)", $rf, $deter, $m ) );
	#$scatterPlots[$rf]["lr"]->SetWeight(2);
	#$scatterPlots[$rf]["lr"]->SetColor($color);
	$al = new PlotLine( HORIZONTAL, $yAverage, $color, 2 );
	$scatterPlots[$rf]["lr"] = $al;
	if ($rfIn == "") { $scatterPlots[$rf]["lr"]->SetLegend( sprintf( "%s\nave=%0.3f n=%s", $rf, $yAverage, count($dataPoints) ) ); }
	$graph->Add( $scatterPlots[$rf]["lr"] );

	$now = new ScatterPlot( array($yAverage), array(time()) );
	$graph->Add( $now );
}

$graph->legend->SetPos(0.00, 0.05, 'right', 'top');
$graph->legend->SetFrameWeight(2);
$graph->legend->SetShadow();
$graph->legend->SetMarkAbsSize(6);
$graph->legend->SetColumns(2);
$graph->xaxis->SetLabelAngle(90);
$graph->Stroke();
?>
