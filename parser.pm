package tab_list::from_html;

use strict;
use HTML::TableExtract;

sub new            ($$);
sub read_next       ($);
sub set_param      ($$);
sub param           ($);

use lib '..';
use _ctrl;
use _fmt;

1;

sub new ($$)
{
  my ($html_path, $html) = @_;
  my $this  = bless {};
  return undef unless $html;
  my $te = new HTML::TableExtract( subtables => 1 );
  my $ts;
  $te->parse_file( $html_path.$html );
  $html =~ s/\.htm$//io unless ($html =~ s/\.html$//io);
  $this->{html} = $html;
  my $rows = [];
  my ($c1, $row);
  foreach $ts ($te->table_states)
  {
    foreach $row ($ts->rows)
    {
      push @{$rows},$row;
      $c1 = @{$row} if ($c1 < @{$row});
    }
    $this->{c1} = $c1-1;
  }
  $this->{value} = $rows;
  $this->{active} = -1;
  $this->{r}  = -1;
  $this->{r1} = @{$rows} - 1;
  return $this;
}


sub read_next ($)
{
  my $this = $_[0];
  return $this->{html} if ($this->{active}++ == -1);
  $this->{active} = 0;
  return undef if ($this->{r}++ > $this->{r1});
  return $this->{value}->[$this->{r}];
}

sub set_param($$)
{
  my ($this,$ref) = @_;
  $this->{param} = $ref;
}

sub param($)
{
  my ($this) = @_;
  return $this->{param};
}



#########################################################################

package tab_list::from_csv;

use strict;

sub parse  ($$$$);

1;

sub parse($$$$){
  my ($from_dir,$csv_file,$to_dir,$res_file) = @_;
  my ($line,$one_column);

  my @columns=();

  if ($from_dir){
    open CSV, "<$from_dir/$csv_file";
  }else{
    open CSV, "<$csv_file";
  }
  if ($to_dir){
    open RES, ">$to_dir/$res_file";
  }else{
    open RES, ">$res_file";
  }
 


  while ($line=<CSV>)
  {
    $line =~ s/\s+/ /g;
    $line =~ s/\x0D\x0A/ /g;
    $line =~ s/\x09\x0A/ /g;
    @columns =();
    while ($line =~ s/^\s*"(.*?)"(;|$)// or $line =~ s/^\s*(.*?)(;|$)// )
    {
      push @columns, $1;
      last unless $line =~ /\S+/;
    }

    for (@columns)
    {
      $one_column = $_;
      $one_column =~ s/\t/ /g;

      $one_column =~ s/\s+/ /g;
      $one_column =~ s/\x0D\x0A/ /g;
      $one_column =~ s/\x09\x0A/ /g;


    
      print RES "$one_column\t";
    }
    print RES "\n";
  }

  close RES;
  close CSV;
}

#########################################################################

package tab_list::from_txt;

use strict;

sub parse  ($$$$);

1;

sub parse($$$$){
  my ($from_dir,$txt_file,$to_dir,$res_file) = @_;
  my ($line);
  if ($from_dir){
    open TXT, "<$from_dir/$txt_file";
  }else{
    open TXT, "<$txt_file";
  }
  if ($to_dir){
    open RES, ">$to_dir/$res_file";
  }else{
    open RES, ">$res_file";
  }
  while ($line=<TXT>){
    $line =~ s/\t/\|\|/g;
    $line =~ s/\s+/ /g;
    $line =~ s/\|\|/\t/g;
    print RES "$line\n";
  }
  close RES;
  close TXT;
}


#########################################################################
