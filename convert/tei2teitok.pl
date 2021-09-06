use XML::LibXML;
use Getopt::Long;

$\ = "\n"; $, = "\t";

binmode(STDOUT, ":utf8");

GetOptions (
            'debug' => \$debug,
            'verbose' => \$verbose,
            'in=s' => \$filename,
            'out=s' => \$outfile,
        );

if ( !$filename ) { $filename = shift; };
if ( !$outfile ) { $outfile = $filename; };

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

# Rename <w> to <tok>
my $rename_attr = {msd => 'feats', pos => 'upos'};
foreach $node ( $xml->findnodes("//w | //pc") ) {
	$nodetype = $node->getName();
	$node->setName("tok");
	while ( my ( $old, $new ) = each %$rename_attr ) { 
		my $attrnode = $node->getAttributeNode( $old );
		if($attrnode) {
			$attrnode->unbindNode();
			$node->setAttribute($new, $attrnode->getValue())
		}
	}
	if($node->hasAttribute('ana')) {
		my $val = $node->getAttribute('ana');
		$val =~ s/^.*pdt:([^ "]+).*?$/$1/;
		$node->setAttribute('xpos', $val);
		$node->removeAttribute('ana');
	}
	$id = $node->getAttribute("id")."";
	$id2node{$id} = $node;
	$join = $node->getAttribute('join')."";
	$node->setAttribute("type", $nodetype);
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

open FILE, ">$outfile";
# binmode(FILE, ":utf8");
print FILE $xml->toString;
close FILE;

print "Saved to $outfile";
