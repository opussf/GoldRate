<?php
#########
# This serves the goldRate data as the Google Chart Tools Datasource Protocol
# AKA Google Visualization API wire protocol.
#
# https://developers.google.com/chart/interactive/docs/dev/implementing_data_source?hl=en

# Parameters to handle: tq, tqx, and tqrt (reserved: ignore this parameter)

$dataFile = "GR.json";

print_r($_GET);
$rfIn = stripslashes($_GET["rf"]);

if (array_key_exists( "tq", $_GET )) {
	$tqIn = $_GET["tq"];
}
if (array_key_exists( "tqx", $_GET )) {
	$tqxIn = $_GET["tqx"];
}
# ignore tqrt parameter
$rfIn = stripslashes($_GET["rf"]);

$jsonString = file_get_contents( $dataFile );

print($jsonString);

?>
