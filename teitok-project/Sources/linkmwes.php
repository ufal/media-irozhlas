<?php

	# mwe and link document view
	# Matyáš Kopp, 2022

	if ( !$_GET['cid'] ) $_GET['cid']  = $_GET['id'];


	$annotation_type = $_GET['annotation_type'] or $annotation_type = 1;

	$viewname = $settings['xmlfile']['linkmwes'][$annotation_type]['title'] or $viewname = "MWEs and links View";
  $linkmweslist = $settings['xmlfile']['linkmwes'][$annotation_type]['tags'];
	$typejson = array2json($linkmweslist);
	$linkto = $settings['xmlfile']['linkmwes'][$annotation_type]['arrowhead'];
	$colorattr = $settings['xmlfile']['linkmwes'][$annotation_type]['attribcolor'];

/*
	$nn2rn = array (
		"person" => "persName",
		"org" => "orgName",
		"place" => "placeName",
	);
	$nn2sn = array (
		"person" => "listPerson",
		"org" => "listOrg",
		"place" => "listPlace",
	);
	$rn2nn = array (
		"persName" => "person",
		"orgName" => "org",
		"placeName" => "place",
	);

	// Load the tagset 
	if ( $settings['xmlfile']['linkmwes']['tagset'] != "none" ) {
		$tagsetfile = $settings['xmlfile']['linkmwes']['tagset'] or $tagsetfile = "tagset-linkmwes.xml";
		require ( "$ttroot/common/Sources/tttags.php" );
		$tttags = new TTTAGS($tagsetfile, false);
		if ( $tttags->tagset['positions'] ) {
			$tmp = $tttags->xml->asXML();
			$tagsettext = preg_replace("/<([^ >]+)([^>]*)\/>/", "<\\1\\2></\\1>", $tmp);
			$maintext .= "<div id='tagset'>$tagsettext</div>";
		};
	};

	$linkmwesfile = $settings['xmlfile']['linkmwes']['linkmwesfile'] or $linkmwesfile = "linkmwes.xml";
	$linkmwesbase = $linkmwesfile;
	if ( strpos($linkmwesfile, "/") == false ) $linkmwesfile = "Resources/$linkmwesfile";
	if ( file_exists($linkmwesfile) ) $linkmwesxml = simplexml_load_file($linkmwesfile);
*/
  if ( $_GET['cid'] ) {

		require("$ttroot/common/Sources/ttxml.php");
		$ttxml = new TTXML();
		$fileid = $ttxml->fileid;
		$xmlid = $ttxml->xmlid;
		$xml = $ttxml->xml;

		$maintext .= "<h2>{%$viewname}</h2><h1>".$ttxml->title()."</h1>";
		$maintext .= $ttxml->tableheader();
		$maintext .= $ttxml->pagenav;
		$maintext .= "<div id=mtxt>".$ttxml->asXML()."</div>";
		
		$maintext .= "<hr>".$ttxml->viewswitch();
		# $maintext .= " &bull; <a href='index.php?action=$action&act=list&cid=$ttxml->fileid'>{%List attributions}</a>";
		if ( $username ) $maintext .= " &bull; <a href='index.php?action=$action&act=detect&cid=$ttxml->fileid' class=adminpart>{%Auto-detect names}</a>";
				
		$maintext .= "
			<style>
				#mtxt tok:hover { text-shadow: none;}
			  #mtxt p { line-height: 200%;}

			</style>
			<script language=Javascript>
			var username = '$username';
			var linkmweslist = $typejson;
			var linkto = '$linkto';
			var colorattr = '$colorattr';


			var hlid = '{$_GET['hlid']}';
			var jmp = '{$_GET['jmp']}';
			var fileid = '$ttxml->fileid';
			$moreaction
			</script>
			<script src=\"Scripts/leader-line.min.js\"></script>
			<script language=Javascript src=\"Scripts/linkmwes.js\"></script>";

	} else if ( $_GET['type'] || count($linkmweslist) == 1 ) {



	} else {
	
		# List of types of NER we have
		$maintext .= "<h2>{%$linkmwestitle}</h2><h1>{%Select}</h1>";
		
		foreach ( $linkmweslist as $key => $val ) {
			$maintext .= "<p><a href='index.php?action=$action&type=$key'>{$val['display']}</a>";
		};

	};
	


?>