<?php
error_reporting(0);
require_once('jpgraph/jpgraph.php');
require_once('jpgraph/jpgraph_scatter.php');
require_once('jpgraph/jpgraph_line.php');
require_once('jpgraph_utils.inc.php');
require_once('jpgraph/jpgraph_date.php');
#require_once('jpgraph/jpgraph_log.php');

#init the jpgraph
$graph = new Graph(1024,768);
$graph->SetScale("datlin");
 
$graph->img->SetMargin(60,40,40,40);        
$graph->SetShadow();
 
$graph->title->Set("Gold progress");
$graph->title->SetFont(FF_FONT1,FS_BOLD);

# Read CSV file
$lineNum = 0;
$factionData = array();
$file = fopen("GR.csv", "r");
while( $line = fgets($file) ) {
	$lineNum += 1;
	if ($lineNum == 1) { $header = explode(",", $line); }
	else {
		$data = explode(",", $line);
		$rf = $data[0]."-".$data[1];
		$x = $data[3];
		$y = $data[4];
		if (strlen($rf) > 2) {
			$factionData[$rf][intval($x)] = intval($y/10000);
		}
	}
}

#print_r($header);
#print_r($factionData);
$cf = new ColorFactory();

$scatterPlots = array();
foreach( $factionData as $rf => $dataPoints ) {
	$scatterPlots[$rf]["datax"] = array_keys($dataPoints);
	$scatterPlots[$rf]["datay"] = array_values($dataPoints);
	$scatterPlots[$rf]["sp"] = new ScatterPlot($scatterPlots[$rf]["datay"], $scatterPlots[$rf]["datax"]);
	$scatterPlots[$rf]["sp"]->SetLegend($rf);
	$scatterPlots[$rf]["sp"]->mark->SetType(MARK_FILLEDCIRCLE);
	$color = $cf->getColor();
	$scatterPlots[$rf]["sp"]->mark->SetFillColor($color);
	$scatterPlots[$rf]["sp"]->mark->SetWidth(4);
	$scatterPlots[$rf]["sp"]->link->Show();
	$scatterPlots[$rf]["sp"]->link->SetWeight(2);
	$scatterPlots[$rf]["sp"]->link->SetColor($color."@0.7");
	$graph->Add($scatterPlots[$rf]["sp"]);
	
	$lr = new LinearRegression( $scatterPlots[$rf]["datax"], $scatterPlots[$rf]["datay"] );
	#print($rf." = ".count($dataPoints)."<br/>");
	list( $stderr, $corr, $deter ) = $lr->GetStat(); # stderr, correlation coefficient, determination coefficient
	list( $a, $m ) = $lr->GetAB();
	list( $xd, $yd ) = $lr->GetY( min($scatterPlots[$rf]["datax"]), time(), 3600 );
	$scatterPlots[$rf]["lr"] = new LinePlot( $yd, $xd );
	$scatterPlots[$rf]["lr"]->SetLegend(sprintf("%s\n(r^2=%0.3f, m=%0.3f)", $rf, $deter, $m ) );
	$scatterPlots[$rf]["lr"]->SetWeight(2);
	$scatterPlots[$rf]["lr"]->SetColor($color);
	$graph->Add( $scatterPlots[$rf]["lr"] );

}
#print_r($scatterPlots);

# build first scatterPlot
#$datax = array_keys($factionData["Hyjal-Alliance"]);
#$datay = array_values($factionData["Hyjal-Alliance"]);
#print_r($datay);

 
#$sp1 = new ScatterPlot($datay,$datax);
#$sp1->SetLegend("Hyjal-Alliance");
#$lr1 = new LinearRegression($datax, $datay);
#$xMin = min($datax);
#$xMax = max($datax);
#list( $xd, $yd ) = $lr1->GetY($xMin,$xMax);

#$lp1 = new LinePlot($yd);
 
#$graph->Add($sp1);
#$graph->Add($lp1);
$graph->legend->SetPos(0.05, 0.05, 'left', 'top');
$graph->legend->SetFrameWeight(2);
$graph->legend->SetShadow();
$graph->legend->SetMarkAbsSize(6);
$graph->legend->SetColumns(2);
$graph->xaxis->SetLabelAngle(90);
$graph->Stroke();
?>
