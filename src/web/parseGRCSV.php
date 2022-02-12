<?php
function parseGRCSV( $rfIn = "", $age = "" ) {
	# rfIn: realmFaction to filter for
	# age: string to control data range
	# returns $factionData: Array
	# factionData[rf][ts] = val

	#$print("rfIn = '$rfIn', age = '$age'");

	$ageMap = array( "1D" => 24* 60 * 60,
			"3D" => 3*24*60*60,
			"1W" => 7*24*60*60,
			"2W" => 14*24*60*60,
			"1M" => 30*24*60*60,
			"2M" => 60*24*60*60 );
	$age = strtoupper( $age );
	
	$minTS = (strlen($age)==2) ? strtotime("midnight",time()-$ageMap[$age]) : 0;

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
			#print($x.">=?".$minTS.":".(($x >= $minTS) ? "true" : "false"));
			if ( strlen($rf) > 2 and $x >= $minTS ) {
				if (((strlen($rfIn) > 2) && ($rf == $rfIn)) || ($rfIn == "")) {
					$factionData[$rf][intval($x)] = floatval($y/10000); # convert to gold and store
				}
			}
		}
	}
	return $factionData;
}

?>
