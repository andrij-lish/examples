package gen;

use strict;
no strict "refs";

use publish;

use lib '..';
use _ctrl;
use _loc;

1;

sub make ($@) {
   my ($package, @param) = @_;
   my $dir = "$loc::lib_path/_$package";

   if (-f "$dir/$package.pm") {
      chdir $dir;
      require "$package.pm";

      my $data = {'package' => $package, 'param_list' => \@param};
      gen ($data, '');

   } else {
      print "File $dir/$package.pm do not exists\n";
      print "Package $package is undefined...\n";
   }
}

sub gen ($$) {
   my ($data, $parent) = @_;
   my ($name, $object);

   return unless $name = $data->{package} and $object = &{"$name\::new"}($data, $parent);

   print ".$object->{label}{id}\n";

   $object->{parent}  = $parent;
   $object->{bobject} = [];

   for (@{$object->{babies}}) {
     push @{$object->{bobject}}, gen ($_, $object);
#      gen ($_, $object);
   }

   publish::make $object->{start_page_address}, $object;
   $object->close if defined &{"$name\::close"};

   return $object;
}


