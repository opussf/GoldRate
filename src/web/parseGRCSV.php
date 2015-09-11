<?php
function parseGRCSV( $rfIn = "" ) {
	# returns $factionData: Array
	$lineNum = 0;
	$factionData = array();
	$file = fopen("GR.csv", "r");
	while( $line = fgets( $file ) ) {
		$lineNum += 1;
		if ( $lineNum == 1 ) { $header = explode( ",", $line ); }
		else {
			$data = explode( ",", $line );
			$rf = $data[0]."-".$data[1];
			$x = $data[3]; # date
			$y = $data[4]; # copper
			if ( strlen($rf) > 2 ) {
				if (((strlen($rfIn) > 2) && ($rf == $rfIn)) || ($rfIn == "")) {
					$factionData[$rf][intval($x)] = floatval($y/10000); # convert to gold and store
				}
			}
		}
	}
	return $factionData;
}

?>
