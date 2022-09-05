#!/usr/bin/perl

use warnings;
use strict;
use XML::LibXML;
use Getopt::Long;
use List::Util;

use Data::Dumper qw(Dumper);

# $\ = "\n"; $, = "\t";

binmode(STDOUT, ":utf8");

my ($debug,$verbose,$filename,$anafilename,$txtfilename,$outfile,$subcorpus);
GetOptions (
            'debug' => \$debug,
            'verbose' => \$verbose,
            'in=s' => \$filename,
            'ana=s' => \$anafilename,
            'txt=s' => \$txtfilename,
            'out=s' => \$outfile,
            'subcorpus=s' => \$subcorpus,
        );

if ( !$filename ) { $filename = shift; };
if ( !$outfile ) { $outfile = $filename; };

my ($raw,$xml,%ana,$txt,$teitext);
my %token_text_map;


# XML file
print "processing: $filename\n";
open FILE, $filename;
binmode(FILE, ":utf8");
{
  local $/;
  $raw = <FILE>;
}
close FILE;

my $parser = XML::LibXML->new();
eval {
  $xml = $parser->load_xml(string => $raw, load_ext_dtd => 0);
};

# BRAT ANA file
print "\tana: $anafilename\n";
open FILE, $anafilename;
binmode(FILE, ":utf8");
$ana{R} = {}; # from => {to => 'T#', attr => 'attrtype'}
$ana{T} = {}; # T# => {start => ..., end => ..., text => ..., ana => ..., }
$ana{pos} = {}; # start => T#
$ana{id} = {}; # mapping T# -> xml:id
my $cnt = 1;
while(my $line = <FILE>) {
	$line =~ s/[ \n]*$//;
  my @line = $line =~ m/^([TR]\d+)\t([^\s]*) (?:Arg1:)?([^\s]*) (?:Arg2:)?([^\s]*)\t? *(.*?)[ \n]*$/;
  my %hash;
  my @keys;
  if($line[0] =~ m/T\d+/){
    @keys = qw/brat_id ana start end text/
  } elsif ($line[0] =~ m/R\d+/) {
    @keys = qw/brat_id ana from to/;
  } else {
    print STDERR "ERROR: $anafilename:$cnt invalid line format '$line'\n";
  }
  if(@keys){
    @hash{@keys} = @line;
    $hash{line} = $line;
    $ana{substr($hash{brat_id},0,1)}->{$hash{brat_id}} = \%hash ;
    $ana{pos}->{$hash{start}} = $hash{brat_id} if $hash{start};
  }
  $cnt++;
}
close FILE;
# corresponding TXT file
print "\ttxt: $txtfilename\n";
open FILE, $txtfilename;
binmode(FILE, ":utf8");
{
  local $/;
  $txt = <FILE>;
}
close FILE;

$teitext='';

foreach my $node ( $xml->findnodes("//*[contains(' w pc ', concat(' ',local-name(),' '))]") ) {
	my $start = length($teitext);
  $teitext .= $node->textContent();
  my $last_pos = length($teitext);
  $teitext .= ' ' unless $node->getAttribute('join') and $node->getAttribute('join') eq 'right';
  $token_text_map{$start} = {
  	                          id => $node->getAttributeNS('http://www.w3.org/XML/1998/namespace','id'),
  	                          last_pos => $last_pos,
  	                          next_pos => length($teitext),
  	                          node => $node
  	                        };

};

my $root_id = $xml->documentElement()->getAttributeNS('http://www.w3.org/XML/1998/namespace','id');

my %aligned_indexes;
my %aligned_indexes_rev;
for my $pair (@{align_text($txt,$teitext)}) {
	$aligned_indexes{$pair->[0]} //= [];
	push @{$aligned_indexes{$pair->[0]}},$pair->[1];
	$aligned_indexes_rev{$pair->[1]} //= [];
	push @{$aligned_indexes_rev{$pair->[1]}},$pair->[0];
}

my ($spanGrp_node, $linkGrp_node);

if(my $text_node = $xml->findnodes("//*[local-name() = 'text'][1]")->[0]){
  $spanGrp_node = $text_node->addNewChild('http://www.tei-c.org/ns/1.0','spanGrp');
  $spanGrp_node->setAttribute('type','ATTRIBUTION');
  $linkGrp_node = $text_node->addNewChild('http://www.tei-c.org/ns/1.0','linkGrp');
  $linkGrp_node->setAttribute('targFunc','signal source');
  $linkGrp_node->setAttribute('type','ATTRIBUTION');

} else {
	die "missing text element"
}
my $mwe_cnt=1;
for my $mwe (sort {$a->{start} <=> $b->{start}} values %{$ana{T}}){
  my @tokens;
  my $token;
  $token = $token_text_map{$aligned_indexes{$mwe->{start}}->[0]};
  if($token){
    push @tokens,$token->{id};
    while($token && $token->{next_pos} < $aligned_indexes{$mwe->{end}}->[0]){
      $token = $token_text_map{$token->{next_pos}};

      last unless $token;
      push @tokens,$token->{id} if $token;
    }
    $mwe->{tei_ids} = [@tokens];
    if(scalar(@tokens) == 1){
      $mwe->{tei_id} = $tokens[0];
      $token->{node}->setAttribute('ana',join(' ',$token->{node}->getAttribute('ana'), 'attrib:'.$mwe->{ana}));
    } else {
      $mwe->{tei_id} = sprintf("$root_id.mwe%d",$mwe_cnt);
      my $span = $spanGrp_node->addNewChild('http://www.tei-c.org/ns/1.0','span');
      $span->setAttributeNS('http://www.w3.org/XML/1998/namespace','id',$mwe->{tei_id});
      $span->setAttribute('ana','attrib:'.$mwe->{ana});
      $span->setAttribute('target',join(' ',map {"#$_"} @tokens));
      $mwe_cnt++
    }
  } else {
  	print STDERR "ERROR: token not found - '",$mwe->{line},"'"
  }
}



for my $rel (sort {$a->{brat_id} cmp $b->{brat_id}} values %{$ana{R}}){
	my $link = $linkGrp_node->addNewChild('http://www.tei-c.org/ns/1.0','link');
  $link->setAttribute('ana','attrib:'.$rel->{ana});
  $link->setAttribute('target',join(' ',map {'#'.$ana{T}->{$rel->{$_}}->{tei_id} } qw/to from/));
  print join(" ==(".$rel->{ana}.")==> " ,map {sprintf("%s [%s](%s)",$_->{text},$_->{tei_id},$_->{ana})} map {$ana{T}->{$rel->{$_}}} qw/from to/),"\n";
}

append_attribute($xml->documentElement(),'ana',"#$subcorpus") if $subcorpus;

open FILE, ">$outfile";
# binmode(FILE, ":utf8");
print FILE $xml->toString;
close FILE;
print "Saved to $outfile\n";


sub align_text { # Needleman-Wunsch algorithm
  my ($t1,$t2) = @_;
  my $gap_penalty = 1;
  my $change_penalty = 1;
  my @alignment = ();
  my @dist = map { [(0) x (length($t2)+1)] }  (0..length($t1));
  $dist[$_]->[0] = $_ * $gap_penalty for (0..length($t1));
  $dist[0]->[$_] = $_ * $gap_penalty for (0..length($t2));

  for my $i (1..length($t1)){
    for my $j (1..length($t2)) {
      if(substr($t1,$i-1,1) eq substr($t2,$j-1,1)){
        $dist[$i]->[$j] = $dist[$i-1]->[$j-1]
      } else {
        $dist[$i]->[$j] =List::Util::min($dist[$i-1]->[$j-1] + $change_penalty,
                                         $dist[$i-1]->[$j] + $gap_penalty,
                                         $dist[$i]->[$j-1] + $gap_penalty);
      }
    }
  }

  my ($i,$j) = (length($t1),length($t2));
  while(!($i==0 || $j==0)) {
    if(substr($t1,$i-1,1) eq substr($t2,$j-1,1)){
      $i--;
      $j--;
    } elsif ($dist[$i-1]->[$j-1] + $change_penalty == $dist[$i]->[$j]) {
      $i--;
      $j--;
    } elsif ($dist[$i-1]->[$j] + $gap_penalty == $dist[$i]->[$j]) {
    	$i--;
    } elsif ($dist[$i]->[$j-1] + $gap_penalty == $dist[$i]->[$j]) {
    	$j--;
    }
    push @alignment, [$i,$j];
  }
  push @alignment, [--$i,$j] while $i > 0;
  push @alignment, [$i,--$j] while $j > 0;

  return [reverse @alignment];
}

sub append_attribute {
	my ($node,$name,$value) = @_;
	$node->setAttribute($name, ($node->hasAttribute($name) ? $node->getAttribute($name).' ' : '') . $value);
}