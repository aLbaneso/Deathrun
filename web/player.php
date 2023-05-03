<?php
	include 'config.php';
	include 'countries.php';

	$playerlist = [];
	$maps = [];

	$result = $mysqli->query("SELECT * FROM `".$maplist."`;");

	if (!empty($result)) {
		while ($data = $result->fetch_assoc()) {
			$player = get_map_best($data["map"]);
			array_push($maps, $data["map"]);

			if (!empty($player)){
				array_push($playerlist, $player["player_id"]);
			}
		}
	}

	$counts = array_count_values($playerlist);
	arsort($counts);
	$dude = array_keys($counts);

	$gotoplayer = false;
	$gotoid = 0;
	$title = "";

	if (isset($_GET['id'])) {
		$gotoid = $_GET['id'];
		
		$info = get_player_info($gotoid);
		if (!empty($info["name"])){
			$gotoplayer = true;
			$title = $info["name"]."'s stats | ";
		}
	}
?>

<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="css/style.css">

		<link rel="icon" href="image/logo.png">
		<meta name="description" content="Deathrun Records">
		<meta property="og:description" content="Deathrun Records">
		<meta name="keywords" content="Deathrun Records">
		<meta name="author" content="admin@example.com">

		<title><?php echo $title.$server_name;?></title>
	</head>

	<body>
	<center>
		<table class="styled-table">
			<?php if ($gotoplayer == false){ ?>
			<thead>
				<tr>
					<th scope="col" style="text-align:right;">#</th>
					<th>Player</th>
					<th>Ranked #1</th>
				</tr>
			</thead>

			<tbody>
				<?php
					$i = 1;
					foreach($dude as $dud){ ?>
						<tr> 
							<td style="text-align:right;"><?php echo $i; $i++;?></td>
						<?php
						$name = get_player_name($dud);
						if ($enable_geoip == true){
							$info = get_player_geoip($dud);
							if (!empty($info["country_code"])){ ?>
								<td><img class="scale" src=<?php echo "image/flags/".strtolower($info["country_code"]).".png";?>> <?php echo $name;?></td>
							<?php }

							else { ?>
									<td><?php echo $name;?></td>
							<?php }
						}

						else { ?>
							<td><?php echo $name;?></td>
						<?php } ?>
					<td><?php echo $counts[$dud]." map(s)";?></td>
				</tr>
					<?php } ?>
			</tbody>
		</table>
		<ul class="pagination">
			<li class="start"><a href="index.php">HOME</a></li>
		</ul>
		<?php } 
			else { 
				sort($maps) ?>
		<table class="styled-table">
			<thead>
				<th scope="col" style="text-align:right;">ID</th>
				<th>Name</th>
				<?php if ($enable_steamid == true){?>
						<th>Steam ID</th>
				<?php } ?>
				<?php
					if ($enable_geoip == true){?>
						<th>Country</th>
				<?php } 
				
				if ($enable_last_active == true){?>
					<th>Last Active</th>
				<?php } ?>
			</thead>

			<tbody>
				<td style="text-align:right;"><?php echo $gotoid;?></td>
				<td><?php echo $info["name"];?></td>
				<?php if ($enable_steamid == true){?>
					<td><?php echo $info["steamid"]; }?></td>
				<?php
					$geoid = get_player_geoip($gotoid);
					if ($enable_geoip == true){
						if (!empty($geoid["country_code"])){?>
							<td><img class="scale" src=<?php echo "image/flags/".strtolower($geoid["country_code"]).".png";?>> <?php echo $countries[$geoid["country_code"]];?></td>
						<?php }

						else { ?>
							<td>n/a</td>
						<?php }
					}
					if ($enable_last_active == true){?>
						<td><?php echo (!empty($geoid["timestamp"])) ? time_elapsed_string($geoid["timestamp"]) : "n/a";?></td>
					<?php } ?>

			</tbody>
		</table>
		<table class="styled-table">
			<thead>		
				<th scope="col" style="text-align:right;">#</th>
				<th>Map</th>
				<th>Record <?php echo $enable_rank_in_personal_stats ? "(rank)" : ""?></th>
				<th>Date</th>
			</thead>

			<tbody>
				<?php
					$i = 1;
					foreach ($maps as $map){
						$rank = 0;
						if ($enable_rank_in_personal_stats){
							$rank = get_player_rank($gotoid, $map);
						}
						$data = get_player_map_data($gotoid, $map);
						if (!empty($data)){?>
							<tr>
								<td style="text-align:right;"><?php echo $i; $i++;?></td>
								<td><?php echo $map;?></td>
								<td><?php echo $rank ? CalculateTimer($data["record"])." (".$rank.")" : CalculateTimer($data["record"]);?></td>
								<td><?php echo time_elapsed_string($data["timestamp"]);?></td>
						<?php } ?>
					</tr>
				<?php } ?>
			</tbody>
		</table>
		<ul class="pagination">
			<li class="start"><a href="index.php">HOME</a></li>
			<li>|</li>
			<li class="start"><a href="?">BACK</a></li>
		</ul>
		<?php } ?>
	</center>
	</body>
</html>