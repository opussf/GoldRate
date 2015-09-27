<?php
error_reporting(0);
require_once('jpgraph/jpgraph.php');
require_once('jpgraph/jpgraph_scatter.php');
require_once('jpgraph/jpgraph_line.php');
require_once('jpgraph_utils.inc.php');
require_once('jpgraph/jpgraph_date.php');
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
$factionData = parseGRCSV($rfIn, $_GET["period"]);

#init the jpgraph
$graph = new Graph( $graphSizes[$size]["x"], $graphSizes[$size]["y"] );
$graph->SetScale("datlin");
if ($rfIn == "") {
	$graph->SetMargin(60,315,40,80);
	$graph->tabtitle->Set("Gold Values");
} else {
	$graph->SetMargin(50,5,20,5); # left, right, top, bottom
	$graph->tabtitle->Set("Gold Values - $rfIn (".count($factionData[$rfIn]).")");
	$graph->xaxis->SetLabelSide(SIDE_TOP);
	$graph->xaxis->SetTextLabelInterval(5);
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
	
	$lr = new LinearRegression( $scatterPlots[$rf]["datax"], $scatterPlots[$rf]["datay"] );
	#print($rf." = ".count($dataPoints)."<br/>");
	list( $stderr, $corr, $deter ) = $lr->GetStat(); # stderr, correlation coefficient, determination coefficient
	list( $a, $m ) = $lr->GetAB();
	list( $xd, $yd ) = $lr->GetY( min($scatterPlots[$rf]["datax"]), time(), 3600 );
	$scatterPlots[$rf]["lr"] = new LinePlot( $yd, $xd );
	#$scatterPlots[$rf]["lr"]->SetLegend(sprintf("%s\n(r^2=%0.3f, m=%0.3f)", $rf, $deter, $m ) );
	$scatterPlots[$rf]["lr"]->SetWeight(2);
	$scatterPlots[$rf]["lr"]->SetColor($color);
	if ($rfIn == "") { $scatterPlots[$rf]["lr"]->SetLegend( sprintf( "%s\nr^2=%0.3f n=%s", $rf, $deter, count($dataPoints) ) ); }
	$graph->Add( $scatterPlots[$rf]["lr"] );

}

$graph->legend->SetPos(0.00, 0.05, 'right', 'top');
$graph->legend->SetFrameWeight(2);
$graph->legend->SetShadow();
$graph->legend->SetMarkAbsSize(6);
$graph->legend->SetColumns(2);
$graph->xaxis->SetLabelAngle(90);
$graph->Stroke();
?>
