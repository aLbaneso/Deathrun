<?php
	include 'config.php';

	$map_id = 0;
	$map_id_table = 0;
	$total_records = 0;
	$maps = [];
	
	$result = $mysqli->query("SELECT * FROM `".$maplist."`;");

	if (!empty($result)) {
		while ($data = $result->fetch_assoc()) {
			$maps[$map_id] = $data["map"];
			$map_id++;
		}
	}

	sort($maps);

	$gotomap = false;
	$specific_map = "";

	if (isset($_GET['map'])) {
		$specific_map = $_GET['map'];

		if (in_array($specific_map, $maps)){
			$gotomap = true;
		}
	}

	if (isset($_GET['page'])) {
		$page = $_GET['page'];
	}
	
	else {
		$page = 1;
	}

	$num_results_on_page = 15;
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
	</head>

	<body>
	<center>
		<?php if ($gotomap == false){ ?>
		<table class="styled-table">
			<!-- <a href="tutorial.html">How to play runs?</a> -->
			<thead>
				<tr>
					<th scope="col" style="text-align:right;">#</th>
					<th>Map Name</th>
					<th>Total Records</th>
					<th>Best Player</th>
					<th>Record</th>
					<th>Date</th>
					<th>Download</th>
				</tr>
			</thead>

			<tbody>
			<?php
				foreach($maps as $map){
					$map_id_table++;
					?>

					<tr>
						<td style="text-align:right;"><?php echo $map_id_table;?></td>
						<td><a href=<?php echo"?map={$map}"?>><?php echo $map;?></a></td>

						<?php
							$map_records = get_map_records($map);
							$total_records += $map_records;
						?>

						<td><?php echo $map_records == 0 ? "-" : $map_records;?></td>

					<?php

						$player = get_map_best($map);

						if (!empty($player)){
							$name = get_player_name($player["player_id"]);
							if ($enable_geoip == true){
								$info = get_player_geoip($player["player_id"]);

								if (!empty($info["country_code"])){ ?>
									<td><a href=<?php echo "player.php?id={$player["player_id"]}";?>><img class="scale" src=<?php echo "image/flags/".strtolower($info["country_code"]).".png";?>> <?php echo $name;?></a></td>
								<?php }

								else { ?>
										<td><a href=<?php echo "player.php?id={$player["player_id"]}";?>><?php echo $name;?></a></td>
								<?php }
							}

							else { ?>
								<td><a href=<?php echo "player.php?id={$player["player_id"]}";?>><?php echo $name;?></a></td>
							<?php } ?>
								<td><?php echo CalculateTimer($player["record"]);?></td>
								<td><?php echo date("F d Y | g:i:s A", $player["timestamp"]);?></td>
								<td><a href=<?php echo "download.php?map={$map}"?>>Unavailable</a></td>
							</tr>
							
						<?php }

						else { ?>
							<td>-</td>
							<td>-</td>
							<td>-</td>
							<td>-</td>
						</tr>
						
						<?php } ?>
					</tr>
					
				<?php } ?>
			</tbody>
		</table>
		<?php }
			else { ?>
				<table class="styled-table">
					<thead>
						<tr>
							<th scope="col" style="text-align:right;">#</th>
							<th>Name</th>
							<th>Record</th>
							<th>Date</th>
						</tr>
					</thead>

					<tbody>
					<?php
					$total_pages = get_map_records($specific_map);
					$total_records += $total_pages;
					$i = 0;

					if ($stmt = $mysqli->prepare("SELECT * FROM `{$specific_map}` ORDER BY `record` ASC LIMIT ?,?;")) {
						$calc_page = ($page - 1) * $num_results_on_page;
						$stmt->bind_param('ii', $calc_page, $num_results_on_page);
						$stmt->execute(); 
						$result = $stmt->get_result();
						
						while ($row = $result->fetch_assoc()){
							$i++ ?>
								<tr>
									<td style="text-align:right;"><?php echo $i+(($page-1) * $num_results_on_page);?></td>
							<?php
								$name = get_player_name($row["player_id"]);

								if ($enable_geoip == true){
									$info = get_player_geoip($row["player_id"]);
									if (!empty($info["country_code"])){	?>
											<td><a href=<?php echo "player.php?id={$row["player_id"]}";?>><img class="scale" src=<?php echo "image/flags/".strtolower($info["country_code"]).".png";?>> <?php echo $name;?></a></td>
									<?php }

									else { ?>
											<td><a href=<?php echo "player.php?id={$row["player_id"]}";?>><?php echo $name;?></a></td>
									<?php }
								}

								else { ?>
									<td><a href=<?php echo "player.php?id={$row["player_id"]}";?>><?php echo $name;?></a></td>
								<?php } ?>
								<td><?php echo CalculateTimer($row["record"]);?></td>
								<td><?php echo date("F d Y | g:i:s A", $row["timestamp"]);?></td>
							</tr>
						<?php }
						$stmt->close();
					}
				} ?>
				</tbody>
			</table>
			<?php
			if ($gotomap == true){
				if (ceil($total_pages / $num_results_on_page) > 0){ ?>
					<ul class="pagination">
					<li class="start"><a href="?">HOME</a></li>
					<li>|</li>
						<?php if ($page > 1){ ?>
							<li class="prev"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page-1 ?>">Prev</a></li>
						<?php } ?>
		
						<?php if ($page > 3){ ?>
							<li class="start"><a href="?map=<?php echo $specific_map?>&page=1">1</a></li>
							<li class="dots">...</li>
						<?php } ?>
		
						<?php if ($page-2 > 0){ ?><li class="page"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page-2 ?>"><?php echo $page-2 ?></a></li><?php } ?>
						<?php if ($page-1 > 0){ ?><li class="page"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page-1 ?>"><?php echo $page-1 ?></a></li><?php } ?>
		
						<li class="currentpage"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page ?>"><?php echo $page ?></a></li>
		
						<?php if ($page+1 < ceil($total_pages / $num_results_on_page)+1){ ?><li class="page"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page+1 ?>"><?php echo $page+1 ?></a></li><?php } ?>
						<?php if ($page+2 < ceil($total_pages / $num_results_on_page)+1){ ?><li class="page"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page+2 ?>"><?php echo $page+2 ?></a></li><?php }?>
		
						<?php if ($page < ceil($total_pages / $num_results_on_page)-2){ ?>
							<li class="dots">...</li>
							<li class="end"><a href="?map=<?php echo $specific_map?>&page=<?php echo ceil($total_pages / $num_results_on_page) ?>"><?php echo ceil($total_pages / $num_results_on_page) ?></a></li>
						<?php } ?>
		
						<?php if ($page < ceil($total_pages / $num_results_on_page)){ ?>
							<li class="next"><a href="?map=<?php echo $specific_map?>&page=<?php echo $page+1 ?>">Next</a></li>
						<?php } ?>
					</ul>
					<?php } } ?>
	</center>
	</body>
	<head>
		<?php
			if ($gotomap == true){
				$title = "{$total_records} Records on {$specific_map} | {$server_name}";
				
			}

			else {
				$title = "{$total_records} Total Records | {$server_name}";
			}
		?>
		<title><?php echo $title;?></title>
	</head>
</html>