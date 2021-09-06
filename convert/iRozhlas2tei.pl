#!/usr/bin/perl

use warnings;
use strict;
use open qw(:std :utf8);
use utf8;
use XML::LibXML qw(:libxml);
use JSON;
use XML::LibXML::PrettyPrint;
use File::Path;

use Getopt::Long;


my ($debug, $test);
my $outdir = "";
GetOptions ( ## Command line options
            'debug' => \$debug, # debugging mode
            'test' => \$test, # do not change the database
            'out-dir=s' => \$outdir
            );


my $json_server = iRozhlas::data::from_json_files->new(@ARGV);
File::Path::mkpath($outdir) unless -d $outdir;



# my $corpus = TEI::media->new(corpus => 1);

my $data_process = iRozhlas::data->new();
my $html_parser = XML::LibXML->new(load_ext_dtd => 0, clean_namespaces => 1, recover => 2);
my $pp = XML::LibXML::PrettyPrint->new(
    indent_string => "  ",
    element => {
        inline   => [qw//], # note
        block    => [qw/person/],
        compact  => [qw/catDesc term desc label date edition title meeting idno orgName persName resp licence language sex forename surname measure head/],
        preserves_whitespace => [qw/s seg note ref p/],
        }
    );

while(my $data = $json_server->next) {

  my $text = $data->{text};
  $data->{text} = '';
  my $xml = obj2xml($data);
  $text =~ s/&nbsp;/ /g;
  my $html =$html_parser->parse_html_string("<html>$text</html>", { encoding => 'utf-8' });
  $xml->find('/ROOT/text')->shift()->appendChild($html->documentElement()->cloneNode(1));

  binmode STDERR;
  my $doc = $data_process->convert('tei',$xml);
  my $doc_id = $doc->documentElement()->getAttributeNS('http://www.w3.org/XML/1998/namespace','id');
  my $cnt = 0;
  for my $node ($doc->findnodes('//*[local-name() = "text"]//*[local-name() = "seg" or local-name() = "head"]')){
    $node->setAttributeNS('http://www.w3.org/XML/1998/namespace','id',"$doc_id.p".(++$cnt));
  }
  save_tei($doc);

  #print STDERR "\n\n============TEXT:\n$text";
#  print STDERR "\n\n============HTML:\n$html";
}


sub save_tei {
  my $doc = shift;
  my $filename = $doc->documentElement()->getAttributeNS('http://www.w3.org/XML/1998/namespace','id');
  my $path = "$outdir/$filename.xml";
  open FILE, ">$path";
  print STDERR "saving to: $path\n";
  binmode FILE;
  $pp->pretty_print($doc);
  my $raw = $doc->toString();
  print FILE $raw;
  close FILE;
}



sub obj2xml {
  my $obj = shift;
  my $dom = XML::LibXML::Document->new("1.0", "utf-8");
  my $root = XML::LibXML::Element->new('ROOT');
  $dom->setDocumentElement($root);
  _obj2xml($root,$obj);
  return $dom;
}

sub _obj2xml {
  my $parent = shift;
  my $obj = shift;
  return $parent unless $obj;
  if(ref($obj) eq 'ARRAY') {
    for my $item (@$obj) {
      my $node = XML::LibXML::Element->new('ITEM');
      $parent->appendChild($node);
      _obj2xml($node,$item);
    }
  } elsif (ref($obj) eq 'HASH') {
    for my $key (keys %$obj) {
      my $node = XML::LibXML::Element->new($key);
      $parent->appendChild($node);
      _obj2xml($node,$obj->{$key});
    }
  } else {
    # print STDERR "convert text to xml??\n";
    $parent->appendText($obj);
  }
}


package iRozhlas::data;
use utf8;
use XML::LibXSLT;
use XML::LibXML;

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = {};
  bless $self, $class;
  $self->{xslt} = XML::LibXSLT->new();
  my $style_tei = get_xml_from_file("convert/tei.xsl");
  #my $style_teiCorpus = XML::LibXML->load_xml(string => $teiCorpusStyle);

  binmode STDERR;
  $self->{tei} = $self->{xslt}->parse_stylesheet($style_tei); # load transformation to tei
  print STDERR "SHEET PARSED!!!\n";
  #$self->{teiCorpus} = $self->{xslt}->parse_stylesheet($style_teiCorpus); # load transformation to teiCorpus
  return $self;
}


sub convert {
  my $self = shift;
  my $type = shift;
  my $xmldata = shift;
  my $result = $self->{$type}->transform($xmldata);

#print STDERR "TEST OUTPUT:",  $self->{$type}->output_as_chars($result);

  return $result;
}

sub get_xml_from_file {
  my $file = shift;
  my $parser = XML::LibXML->new();
  print STDERR "OPENING $file\n";
  local $/;
  open FILE, $file;
  binmode ( FILE, ":utf8" );
  my $raw = <FILE>;
  close FILE;
  my $doc;
  eval { $doc = $parser->load_xml(string => $raw, {no_cdata=>1, no_blanks=>1}) };
  if ( !$doc ) {
      print " -- invalid XML in $file\n";
      print "$@";
    }
  return $doc;
}



package iRozhlas::data::from_json_files;


sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = {};
  $self->{files} = [@_];
  bless $self, $class;
  $self->{json} = JSON->new->allow_nonref;
  $self->{data} = [];
  return $self;
}

sub next {
  my $self = shift;
  # load next file if no open or is at the end of file
  unless (@{$self->{data}}) {
    if(my $file = shift @{$self->{files}}) {
      print STDERR "opening $file\n" if $debug;
      local $/;
      open FILE, $file;
      binmode ( FILE, ":utf8" );
      my $text = <FILE>;
      close FILE;
      $self->{data} = $self->{json}->decode($text);
    } else {
        return undef;
    }
  }
  # get first record from file
  return shift @{$self->{data}}
}

1;