#!/usr/bin/perl

use strict;
use warnings;
use Date::Calc::Object qw(:all);

my $Date_Of_Birth = 0;
my ($resp, $age_in_weeks);

my $hash_with_results = { '0W' => ['ABC', 'DEF', 'XYZ'], '1W' => [], '2W' => [], '3W' => [], '4W' => ['123', '456'], '5W' => [], '6W' => ['123', '456', '78', 'ABC'] } ;

my $find_next_not_empty = 0;
my $next_age_in_weeks = 0;
my $next_control_date = 0;


print "Today: ".Date_to_Text(Date::Calc::Today())."\n";


while (!$Date_Of_Birth)
{
	print "Please enter the date of your birthday (day_month_Year): ";
	$Date_Of_Birth = Date::Calc->new( Decode_Date_EU( scalar(<STDIN>) ) );
	if ($Date_Of_Birth)
	{
		$resp = 0;
		while ($resp !~ /^\s*[YyNn]/)
		{
			print "Your birthday (YYYYMMDD) is : $Date_Of_Birth\n";
			print "Is that correct? (yes/no) ";
			$resp = <STDIN>;
		}
		$Date_Of_Birth = 0 unless ($resp =~ /^\s*[Yy]/)
	}
	else
	{
		print "Unable to parse your birthday. Please try again.\n";
	}
}

my $delta = [Today()] - $Date_Of_Birth;
$delta->normalize();
  
$age_in_weeks = int( abs(abs($delta)) / 7);
print "You age: ".abs(abs($delta))." days, or ".$age_in_weeks." full weeks!\n\n";  
  
for my $key (sort keys %{$hash_with_results} ) 	
{
	my $array_size = @{$hash_with_results->{$key}}; 
	if ( $find_next_not_empty and ($array_size>0) )
	{
		print "NEXT NOT EMPTY: key=".$key.", value from hash: ".join(", ", @{$hash_with_results->{$key}}). "\n";
		if ($key =~ /^(\d+)W$/)
		{
			$next_age_in_weeks = $1;
		}
		$find_next_not_empty = 0;
	}
	if ($key eq $age_in_weeks."W")
	{
		print "CURRENT: key= ".$key.", value from hash= ".join(", ", @{$hash_with_results->{$key}}). "\n";
		$find_next_not_empty = 1;
	}
}

print "Not fount current (for key=".$age_in_weeks."W) values from hash!\n" unless $hash_with_results->{$age_in_weeks."W"};  

if ($next_age_in_weeks>0)
{
	$next_control_date = $Date_Of_Birth + [0,0,$next_age_in_weeks*7];
	print "Next date (for age $next_age_in_weeks week): ".$next_control_date. "\n";
	
}
else
{
	print "Not fount next not empty values from hash!";  
}
  
  






