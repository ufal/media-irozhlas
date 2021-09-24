#!/usr/bin/perl

use warnings;
use strict;
use open qw(:std :utf8);
use utf8;
use XML::LibXML qw(:libxml);
use XML::LibXML::PrettyPrint;
use File::Path;
use Encode;
use Getopt::Long;



my ($filename, $outdir);

GetOptions (
            'in=s' => \$filename,
            'out=s' => \$outdir,
        );

if ( !$filename ) { $filename = shift; };
if ( !$outdir ) { $outdir = '.'; };

open FILE, $filename;
binmode(FILE, ":utf8");
$/ = undef;
my $raw = <FILE>;
close FILE;

my $parser = XML::LibXML->new();
my $xml;
eval {
  $xml = $parser->load_xml(string => $raw, load_ext_dtd => 0);
};


exit unless $xml;

my $pp = XML::LibXML::PrettyPrint->new(
    indent_string => "  ",
    element => {
        inline   => [qw//], # note
        block    => [qw/person list/],
        compact  => [qw/catDesc term desc label date edition title meeting idno orgName persName resp licence language sex forename surname measure head district/],
        preserves_whitespace => [qw/s seg note ref p item/],
        }
    );

foreach my $tei ($xml->findnodes("//*[local-name()='TEI']")) {
  my $dom = XML::LibXML::Document->new("1.0", "utf-8");
  $tei->unbindNode();
  $dom->setDocumentElement($tei);
  my $name = $tei->getAttributeNS('','id').".xml";
  open FILE, ">$outdir/$name";
  $pp->pretty_print($dom);
  print FILE Encode::decode("utf-8", $dom->toString);
  close FILE;
  print "Saved to $outdir/$name\n";
}