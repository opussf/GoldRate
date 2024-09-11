google.charts.load("current", {packages:["corechart", "controls"]});
//google.charts.setOnLoadCallback( function() {console.log("OnLoadCallBack"); });

var app = angular.module('GoldApp', []);
app.controller('GoldDisplay', function( $scope, $http ) {
$scope.chartData = [];

$scope.drawAllCharts = function() {
	console.log( "DrawAllCharts" );
	$scope.chartData = [['Date']];
	for( i in $scope.realmList ) {
		$scope.chartData[0].push( $scope.realmList[i][0] );
	}

	cData = {};  // Collection data structure {date: {realm: value, ... } }
	
	for( i in $scope.gold.realms ) {
		realm = $scope.gold.realms[i].realm;
		for( di in $scope.gold.realms[i].factions[0].data ) {
			ts = $scope.gold.realms[i].factions[0].data[di][0]; // timestamp
			cv = $scope.gold.realms[i].factions[0].data[di][1]; // copper value
			if( !(ts in cData) ) {
				cData[ts] = {};
			}
			cData[ts][realm] = cv;
		}
	}
	for( var ts in cData) {
		lTimeRealmVal = [new Date(ts*1000)]; // date takes ms, data has seconds
		for( i in $scope.realmList ) {
			rn = $scope.realmList[i][0];
			if( rn in cData[ts] ) {
				lTimeRealmVal.push( cData[ts][rn]/10000 );
			} else {
				lTimeRealmVal.push(null);
			}
		}
		$scope.chartData.push( lTimeRealmVal );
	}
	$scope.drawChart( "all_chart_div" );
}

$scope.drawChart = function( div ) {
	console.log( "drawChart( "+ div +" )" );
	console.log(document.getElementById('all_dashboard_div'));
	var dashboard = new google.visualization.Dashboard(document.getElementById('all_dashboard_div'));

	var dateRangeFilter = new google.visualization.ControlWrapper({
		'controlType': 'ChartRangeFilter',
		'containerId': 'all_filter_div',
		'options': {
			'filterColumnLabel': 'Date',
		},
	});

	var options = {
		bar: { groupWidth: '100%' },
		title: "ALL DATA",
		titlePosition: 'out',
		interpolateNulls: true,
		//legend: 'none',
		hAxis: {
			//format: 'MMM d, y',
			format: 'MM/dd/yyyy',
			testPosition: 'out',
			//maxValue: new Date(),
		},
		vAxis: {
			title: 'Gold'
		},
		seriesType: 'line',
		series: {0: {type: 'area'}},
		height: 600,
	};

	var comboChart = new google.visualization.ChartWrapper({
		'chartType': 'ComboChart',
		'containerId': 'all_chart_div',
		'options': options,
	});

	var data = google.visualization.arrayToDataTable( $scope.chartData );
	dashboard.bind( dateRangeFilter, comboChart );
	dashboard.draw(data);

	changeRange = function( rangeVal ) {
		dateRangeFilter.setState(
			{'range': {'start': new Date( Date.now() - rangeVal*1000 ), 'end': new Date()}}
		);
		dateRangeFilter.draw();
	};
	clearRange = function() {
		dateRangeFilter.setState();
		dateRangeFilter.draw();
	};
	changeOptions = function( column ) {
		comboChart.setOption('view', {'columns': [0,column]});
		comboChart.draw();
	}
}

$http.get("GR.json?date="+ new Date())
.then( function( response) { 
console.log("loaded");
$scope.gold = response.data.goldRate;
$scope.graphAgeDays = $scope.gold.graphAgeDays;
$scope.realmList = new Array();
for( i in $scope.gold.realms ) {
	$scope.realmList.push( new Array( $scope.gold.realms[i].realm, $scope.gold.realms[i].factions[0].data.length,
	$scope.gold.realms[i].realm.replace(" ", "_")+"_chart_div") );
	console.log(i, $scope.gold.realms[i]);
}
$scope.realmList.sort( function(a,b) { return a[1]-b[1] } ).reverse();

google.charts.setOnLoadCallback( $scope.drawAllCharts );

}); // http.get.then
}); // app.controler

