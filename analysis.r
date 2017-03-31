package analysis;

use param;
use fmt;
use ctrl;
use strict;
no strict 'refs';

sub run              ($);
sub get_search_param ($);

sub run ($) {
   my $param = shift;
   my ($conf, $html, $f_param, $source, @search_param, $result, $processer, $run);
   
   $html = $param->{html}[0];
   $conf = $param->{conf}[0];

   open FH, $html;
undef $/;
my $source = <FH>;
####      $source .= $_ while (<FH>);
   close FH;
   
   $f_param = param::parse ['-f', $conf];
   print "-" x 30, "\n";
   print "HTML => $html\n";
   print "CONF => $conf\n\n";

   $f_param->{regexp} = [ split ' ~', (join ' ', @{$f_param->{regexp}}) ];
   @search_param = get_search_param [ keys %$f_param ];

   for my $i (0..($f_param->{num}[0] ? $f_param->{num}[0] - 1 : 0)) {
      my ($regexp, $brackets, $all, @anonce);

      for my $one (@search_param) {
         for my $n (split ',', $f_param->{$one}[$i]) {
            $brackets->{$n} = $one;
         }
      }
      
      $all = $f_param->{all}[$i];
      @anonce = $source =~ m~$f_param->{regexp}[$i]~isg;
      my ($j, $elem) = (1, {});
      print "Found$i  => ", scalar (@anonce) / $all, "\n";
      for my $an (@anonce) {
         if ($brackets->{$j}) {
            $elem->{$brackets->{$j}} = ($elem->{$brackets->{$j}}) ? $elem->{$brackets->{$j}} . $an : $an;
         }
         if ($j == $all) {
            push @$result, $elem;
            ($j, $elem) = (0, {});
         }
         $j++;
      }

   }
   
   $processer = '_net/' . (shift @{$f_param->{processer}});
   ctrl::r_require \$processer;
   $run  = "$processer\::run";
   &$run({ 
   		  analysis  => $result, 
   		  processer => $f_param->{processer},
   		  parent    => { 
   		  					  %{$param->{parent}}, 
   		  					  html => $html 
   		  					} 
   	   });
}
   
sub get_search_param ($) {
   my $params = shift;
   my @result = ();
   my @const  = qw/regexp all num processer/;

   for my $param (@$params) {
      my $flag = 0;
      for my $one (@const) {
         $flag = 1 if ($param eq $one);
      }
      push @result, $param unless ($flag);
   }
   return @result;
}

1;