<?php
	$database_server = "localhost";
	$database_username = "server";
	$database_password = "server";
	$database_db = "server";
	$maplist = "maplist";
	$players = "players";
	$enable_steamid = true;
	$enable_geoip = true;
	$enable_last_active = true;
	$enable_rank_in_personal_stats = false; // resource consuming
	$server_name = "Deathrun Server";

	$mysqli = new mysqli($database_server, $database_username, $database_password, $database_db);

	$a = array( 365 * 24 * 60 * 60  =>  'year',
				 30 * 24 * 60 * 60  =>  'month',
					  24 * 60 * 60  =>  'day',
						   60 * 60  =>  'hour',
								60  =>  'minute',
								 1  =>  'second'
	);

	$a_plural = array( 'year'   => 'years',
					   'month'  => 'months',
					   'day'    => 'days',
					   'hour'   => 'hours',
					   'minute' => 'minutes',
					   'second' => 'seconds'
	);

	function get_player_name($id){
		global $mysqli;
		global $players;
		return $mysqli->query("SELECT `name` FROM `".$players."` WHERE `id` = ".$id.";")->fetch_column();
	}

	function get_player_info($id){
		global $mysqli;
		global $players;
		return $mysqli->query("SELECT * FROM `".$players."` WHERE `id` = ".$id.";")->fetch_assoc();
	}

	function get_player_geoip($id){
		global $mysqli;
		return $mysqli->query("SELECT * FROM `geoip` WHERE `id` = ".$id.";")->fetch_assoc();
	}

	function get_player_rank($id, $mapname){
		global $mysqli;
		return $mysqli->query("select 1 + count(*) from `".$mapname."` where `".$mapname."`.`record` < (select `".$mapname."`.`record` from `".$mapname."` where `".$mapname."`.`player_id` = $id);")->fetch_column();
	}

	function get_player_map_data($id, $mapname){
		global $mysqli;
		return $mysqli->query("SELECT * FROM `".$mapname."` WHERE `id` = ".$id.";")->fetch_assoc();
	}

	function get_map_best($mapname){
		global $mysqli;
		return $mysqli->query("SELECT * FROM `".$mapname."` ORDER BY `record` ASC LIMIT 1;")->fetch_assoc();
	}

	function get_map_records($mapname){
		global $mysqli;
		return $mysqli->query("SELECT COUNT(*) FROM `".$mapname."`;")->fetch_column();
	}

	function CalculateTimer($Milliseconds){
		$imin = 0;
		$isec = 0;
		$imil = $Milliseconds;
	
		if ($imil >= 60000){
			$imin = intdiv($imil, 60000);
			$imil = $imil - ($imin * 60000);
		}
	
		if ($imil >= 1000){
			$isec = intdiv($imil, 1000);
			$imil = $imil - ($isec * 1000);
		}
	
		$timer = sprintf('%d:%02d.%02dms', $imin, $isec, $imil);
		return $timer;
	}

	function time_elapsed_string($ptime){
		global $a;
		global $a_plural;

		$etime = time() - $ptime;

		if ($etime < 60){
			return 'just now';
		}

		foreach ($a as $secs => $str){
			$d = $etime / $secs;
			if ($d >= 1){
				$r = round($d);
				return $r . ' ' . ($r > 1 ? $a_plural[$str] : $str) . ' ago';
			}
		}
	}
?>