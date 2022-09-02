use XML::LibXML;
use Getopt::Long;

$\ = "\n"; $, = "\t";

binmode(STDOUT, ":utf8");

GetOptions (
            'debug' => \$debug,
            'verbose' => \$verbose,
            'in=s' => \$filename,
            'out=s' => \$outfile,
            'stand-off-type=s' => \$stand_off_type, # create standoff annotations in spanGrp with type
            'stand-off-pref=s' => \$stand_off_pref, # create standoff annotations from prefix
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

my $spanGrp;
my $linkGrp;
my %word_to_span_id;

if($make_standoff){
	die "make standoff is supported only on a single TEI file\n" if $xml->findnodes('/teiCorpus');
	($spanGrp) = $xml->findnodes("//spanGrp[\@type=\"$stand_off_type\"]");
	unless($spanGrp) {
		$spanGrp = $xml->findnodes("/TEI/text")->[0]->addNewChild('','spanGrp');
		$spanGrp->setAttribute("type",$stand_off_type);
	}
	($linkGrp) = $xml->findnodes("//linkGrp[\@type=\"$stand_off_type\"]");
	print STDERR "LINKGRP:$linkGrp\n";
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
		if($make_standoff) {
		  ($val) = $node->getAttribute('ana') =~ m/^.*\b(${stand_off_pref}:[^ "]+)/;
		  if($val){
		  	my $span = $spanGrp->addNewChild('','span');
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

foreach $node ( $xml->findnodes("//span") ) {
	$id = $node->getAttribute("id")."";
	$id2node{$id} = $node;
	if($node->hasAttribute('ana')) {
		my $val = $node->getAttribute('ana');
		$val =~ s/^.*\b${stand_off_pref}:([^ "]+).*?/$1/;
		$node->setAttribute("${stand_off_pref}_type", $val) if $val;
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

# Set ATTRIBUTION
foreach $node ( $xml->findnodes("//linkGrp[\@type=\"$stand_off_type\"]/link") ) {
	($t1, $t2) = split(" ", $linkGrp->getAttribute('targFunc'));
	($a1, $a2) = split(" ", $node->getAttribute('target'));
	$base = substr($a2, 1);	$head = substr($a1, 1);
	$base = $word_to_span_id{$base} // $base;
	$head = $word_to_span_id{$head} // $head;
	print STDERR "$base -> $head\n";
	if ( $id2node{$base} && $id2node{$head} ) {
		append_attribute($id2node{$base},"${stand_off_pref}_$t1", $id2node{$head}->getAttribute("id"));
		append_attribute($id2node{$head},"${stand_off_pref}_$t2", $id2node{$base}->getAttribute("id"));

	};
};
$linkGrp->unbindNode if $linkGrp;

# Copy head attributes to child
for my $base ( keys %id2node ) {
	my $head = $id2node{$base}->getAttribute("head");
	if ( $id2node{$base} && $head && $id2node{$head} ) {
		for my $att (qw/lemma upos xpos feats type deprel/) {
      $id2node{$base}->setAttribute("head_$att", $id2node{$head}->getAttribute($att)) if $id2node{$head}->hasAttribute($att)
		}
	};
};

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