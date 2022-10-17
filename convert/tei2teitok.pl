use XML::LibXML;
use Getopt::Long;
use String::Substitution;

$\ = "\n"; $, = "\t";

binmode(STDOUT, ":utf8");

GetOptions (
            'debug' => \$debug,
            'verbose' => \$verbose,
            'in=s' => \$filename,
            'out=s' => \$outfile,
            'ana-to-attribute-value=s' => \$ana_to_attribute_value, # move ana values to separate attribute
            'stand-off-type=s' => \$stand_off_type, # create standoff annotations in spanGrp with type
            'stand-off-pref=s' => \$stand_off_pref, # create standoff annotations from prefix
            'stand-off-val-patch=s' => \$stand_off_val_patch,
            'stand-off-remove=s' => \$stand_off_remove,
            'split-corpus' => \$split_corpus,
        );

if ( !$filename ) { $filename = shift; };
if ( !$outfile ) { $outfile = $filename; };

my $make_standoff = ($stand_off_type && $stand_off_pref);

open FILE, $filename;
binmode(FILE, ":utf8");
$/ = undef;
$raw = <FILE>;
close FILE;

$raw =~ s/xmlns/xmlnsoff/g;
$raw =~ s/xml://g;
$raw =~ s/<text>/<text  xml:space="remove">/g;

$parser = XML::LibXML->new(); 
eval {
	$xml = $parser->load_xml(string => $raw, load_ext_dtd => 0);
};

my @stand_off_pref;
my @stand_off_type;

my @spanGrp;
my @linkGrp;
my %word_to_span_id;
my @stand_off_pref_abbr;
my ($stand_off_val_patch_from,$stand_off_val_patch_to);
if($make_standoff){
	die "make standoff is supported only on a single TEI file\n" if $xml->findnodes('/teiCorpus');
  @stand_off_pref = split(/,/, $stand_off_pref);
  @stand_off_type = split(/,/, $stand_off_type);
  @spanGrp = map {undef} @stand_off_type;
  @linkGrp = map {undef} @stand_off_type;
  @stand_off_pref_abbr = map {substr($_,0,1)} @stand_off_pref;
  for my $i (0..$#stand_off_type){
	  ($spanGrp[$i]) = $xml->findnodes("//spanGrp[\@type=\"$stand_off_type[$i]\"]");
	  unless($spanGrp[$i]) {
		  $spanGrp[$i] = $xml->findnodes("/TEI/text")->[0]->addNewChild('','spanGrp');
		  $spanGrp[$i]->setAttribute("type",$stand_off_type[$i]);
	  }
	  ($linkGrp[$i]) = $xml->findnodes("//linkGrp[\@type=\"$stand_off_type[$i]\"]");
	  print STDERR "SPANGRP:$spanGrp[$i]\n";
	  print STDERR "LINKGRP:$linkGrp[$i]\n";
  }
  ($stand_off_val_patch_from,$stand_off_val_patch_to) = split('/', $stand_off_val_patch//'');
  #$stand_off_val_patch_from = eval("qr/${stand_off_val_patch_from}/") if $stand_off_val_patch_from;
  ##$stand_off_val_patch_to = eval("${stand_off_val_patch_to}") if $stand_off_val_patch_to;
}

# Rename <w> to <tok>
my $rename_attr = {msd => 'feats', pos => 'upos'};
foreach $node ( $xml->findnodes("//w | //pc") ) {
	$nodetype = $node->getName();
	$node->setName("tok");
	$id = $node->getAttribute("id")."";
	while ( my ( $old, $new ) = each %$rename_attr ) { 
		my $attrnode = $node->getAttributeNode( $old );
		if($attrnode) {
			$attrnode->unbindNode();
			$node->setAttribute($new, $attrnode->getValue())
		}
	}
	if($node->hasAttribute('ana')) {
		my ($val) = $node->getAttribute('ana') =~ m/^.*pdt:([^ "]+)/;
		$node->setAttribute('xpos', $val) if $val;

		undef $val;
		for my $i (0..$#stand_off_pref){
			my $p = $stand_off_pref[$i];
		  ($val) = $node->getAttribute('ana') =~ m/^.*\b(${p}:[^ "]+)/;
		  String::Substitution::sub_modify($val,$stand_off_remove,'') if $val && $stand_off_remove;
		  if($val){
		  	my $span = $spanGrp[$i]->addNewChild('','span');
		  	my $spanid = "$id.span";
		  	$span->setAttribute("id",$spanid);
		  	$word_to_span_id{$id} = $spanid;
		  	$span->setAttribute("ana",$val);
		  	$span->setAttribute("target","#$id");

		  	print STDERR "adding new span: $span\n";
		  }
	  }
		$node->removeAttribute('ana');
	}

	$id2node{$id} = $node;
	$join = $node->getAttribute('join')."";
	$node->setAttribute("type", $nodetype);
};


for my $i (0..$#stand_off_pref){
	print STDERR "Processing: $stand_off_type[$i]/$stand_off_pref[$i]/$stand_off_pref_abbr[$i]\n";
  foreach $node ( $spanGrp[$i]->findnodes(".//span") ) {
		$id = $node->getAttribute("id")."";
		$id2node{$id} = $node;
		if($node->hasAttribute('ana')) {
	  	my $val = $node->getAttribute('ana');
	  	print STDERR "\t$val\n";
		  my $p = $stand_off_pref[$i];
		  my $a = $stand_off_pref_abbr[$i];
		  $val =~ s/^.*\b${p}:([^ "]+).*?/$1/;
	    String::Substitution::sub_modify($val,$stand_off_val_patch_from,$stand_off_val_patch_to) if $stand_off_val_patch;
	    String::Substitution::sub_modify($val,$stand_off_remove,'') if $stand_off_remove;
	    $node->setAttribute("${a}type", $val) if $val;
	    unless($val){ # remove whole span if no annotation
	      print STDERR "removing span: $node\n";
	      $node->unbindNode;
	    }
	  	$node->removeAttribute('ana');
		}
		if($node->hasAttribute('target')) {
			my $val = $node->getAttribute('target');
			$node->setAttribute('corresp', $val);
			$node->removeAttribute('target');
		}

		# my ($first_tok_id) = $node->getAttribute('target') =~ m/^\s*#([^ ]*)/;
		# $node->unbindNode();
		# $id2node{$first_tok_id}->parentNode->insertBefore($node,$id2node{$first_tok_id});
	};
};

# Rename named entities attributes and remove CNEC prefixes
foreach $node ( $xml->findnodes("//text//*[\@ana][contains(' name date time email ref num unit ',concat(' ',local-name(),' ' ))]") ) {
	my $val = $node->getAttribute('ana');
	if ( $val =~ s/^.*ne:([^ "]+).*?$/$1/ ) {
		$node->setAttribute('cnec', $val);
		$node->removeAttribute('ana');
	}
};

# Set UD back to @head and such
foreach $node ( $xml->findnodes("//linkGrp[\@type=\"UD-SYN\"]/link") ) {
	($a1, $a2) = split(" ", $node->getAttribute('target'));
	($l1, $l2) = split(":", $node->getAttribute('ana'));
	$l2 =~ s/_/:/g;
	$base = substr($a2, 1);	$head = substr($a1, 1);
	if ( $id2node{$base} && $id2node{$head} ) {
		$id2node{$base}->setAttribute("head", $id2node{$head}->getAttribute("id"));
	};
	if ( $id2node{$base} ) {
		$id2node{$base}->setAttribute("deprel", $l2);
	};
};


for my $i (0..$#stand_off_pref){
	# Set ATTRIBUTION / ...
	foreach $node ( $xml->findnodes("//linkGrp[\@type=\"$stand_off_type[$i]\"]/link[\@ana]") ) {
		$val = $node->getAttribute('ana');
		my $p = $stand_off_pref[$i];
		$val =~ s/^.*\b${p}:([^ "]+).*?/$1/;
	  if($stand_off_remove){
	  	String::Substitution::sub_modify($val,$stand_off_remove,'');
		  $node->unbindNode unless $val;
		}
	};

	foreach $node ( $xml->findnodes("//linkGrp[\@type=\"$stand_off_type[$i]\"]/link") ) {
		($t1, $t2) = split(" ", $linkGrp[$i]->getAttribute('targFunc'));
		($a1, $a2) = split(" ", $node->getAttribute('target'));
		$base = substr($a2, 1);	$head = substr($a1, 1);
		$base = $word_to_span_id{$base} // $base;
		$head = $word_to_span_id{$head} // $head;
		print STDERR "$base -> $head\n";
		if ( $id2node{$base} && $id2node{$head} ) {
			my $a = $stand_off_pref_abbr[$i];
	    append_attribute($id2node{$base},"$a$t1", $id2node{$head}->getAttribute("id"));
			append_attribute($id2node{$head},"$a$t2", $id2node{$base}->getAttribute("id"));

		};
	};
  $linkGrp[$i]->unbindNode if $linkGrp[$i];
}

# Copy head attributes to child
for my $base ( keys %id2node ) {
	my $head = $id2node{$base}->getAttribute("head");
	if ( $id2node{$base} && $head && $id2node{$head} ) {
		for my $att (qw/lemma upos xpos feats type deprel/) {
      $id2node{$base}->setAttribute("head_$att", $id2node{$head}->getAttribute($att)) if $id2node{$head}->hasAttribute($att)
		}
	};
};

# ana to attribute-value processing

my @attribute_value_fixtures = map {["$_=$_" =~ m/^([^=]*)=([^=]*)=([^=]*)/ ]} split(/  */,$ana_to_attribute_value//'');
for my $a (@attribute_value_fixtures){
	my ($old_val,$new_attr,$new_val) = @$a;
	foreach $node ( $xml->findnodes("//*[contains(concat(' ',\@ana,' '),' $old_val ')]") ) {
		my $ana = $node->getAttribute('ana');
    $ana =~ s/$old_val\b//g;
    $ana =~ s/  *//g;
    $ana =~ s/^ | $//g;
    if($ana) {
		  $node->setAttribute('ana',$ana)
		} else {
      $node->removeAttribute('ana');
    }
    if($node->hasAttribute($new_attr)){
    	print STDERR "WARN: attribute $new_attr already exists:$node\n";
    	$ana .= ' '.$node->getAttribute($new_attr);
    }
    $node->setAttribute($new_attr,$new_val);
	}
}


#------------

if ( $split_corpus ) {
  foreach $tei ($xml->findnodes("//TEI[\@id]")) {
  	my $dom = XML::LibXML::Document->new("1.0", "utf-8");
  	$tei->unbindNode();
  	$dom->setDocumentElement($tei);
  	my $name = $tei->getAttribute('id').".xml";
  	open FILE, ">$outfile/$name";
    # binmode(FILE, ":utf8");
    print FILE $dom->toString;
    close FILE;
    print "Saved to $outfile/$name";
  }
} else {
  open FILE, ">$outfile";
  # binmode(FILE, ":utf8");
  print FILE $xml->toString;
  close FILE;
  print "Saved to $outfile";
}

sub append_attribute {
	my ($node,$name,$value) = @_;
	$node->setAttribute($name, ($node->hasAttribute($name) ? $node->getAttribute($name).' ' : '') . $value);
}