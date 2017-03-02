package publish;
use strict;

no strict "refs";

use lib '..';
use _loc;
use _fmt;
use _param;
use FileHandle;

sub make    ($$);
# my @ARG   = ('-f', 'publish.cfg');
my @ARG   = ('-f', "$loc::lib_path/_www/publish.cfg");
my $param = param::parse @ARG;

my $cgi_url  = $param->{cgi_url}[0];my $site_name= $param->{site_name}[0];
my $tpl_path = "$loc::backup_path/_www/_tpl";


1;
sub out_insertion      ($$$);
sub out_insertion_file ($$);


#############################

sub make ($$) {
   my ($start_page_address, $object) = @_;
   return unless $start_page_address and $object;

   my $this = bless {};
   $this->{label}{site_name}    = $site_name;
   $this->{label}{cgi_url}      = $cgi_url;
   $this->{label}{data_type}    = (ref $object->{parent}).'::'.(ref $object);
   $this->{label}{data_id}      = "$object->{parent}->{label}{id}::$object->{label}{id}";
   $this->{label}{section}      = $object->{parent}->{label}{section};
   $this->{label}{title}        = $object->{label}{title};
   $this->{label}{referer}      = $object->{label}{referer};

   $this->{node}{id}            = $object->{node}{id};
   $this->{node}{name}          = $object->{node}{name};
   $this->{node}{property}      = $object->{node}{property};
   $this->{node}{property_descr}= $object->{node}{property_descr};
   $this->{node}{parent}{name}  = $object->{node}{parent}{name};

   $this->{object}              = $object;
   $this->{object}->{template}  = $this;

   my $file;
   my $real_out_path = $loc::out_path;
   if ( $start_page_address eq 'STDOUT' )  {
      $file = *STDOUT;
      print $file "content-type: text/html\n\n";
      $this->{label}{name_script} = $object->{name_script};
            $this->{label}{name_script} = $object->{page_address}  unless($this->{label}{name_script});;
      $this->{label}{page_address} = 'STDOUT';
      $this->{label}{page_address} .=time().".htm";
   } else {
      $file = new FileHandle;

#      if ( $start_page_address =~ /^(.*?)\//) 
#      {
#        if ($1 eq 'ru')
#        {
#         $real_out_path = $loc::out_path_ru;
#          $real_out_path = "$loc::out_path/ru" unless $real_out_path;
#          $start_page_address =~ s/^ru\///ig; 
#          print "$real_out_path";
#          <STDIN>;
#        } 
#      }      

      if ( $start_page_address =~ /(.*)\/([^\/]*)/o and not -d "$real_out_path/$1" ) {
          print "Directory $real_out_path/$1 is absent. Creating... \n";
          print "Error creating directory $1\n" unless (mkdir "$real_out_path/$1", 0777);
      }
      my ($page, $ext) = ( $start_page_address =~ /(.*)(\..?htm.?)$/o )
                         ? ($1, $2)
                         : ($start_page_address, '');
      $this->{label}{page_address} = $page.$ext;
      open $file, ">$real_out_path/$this->{label}{page_address}";
   }

   $this->{file} = $file;
   $this->out_insertion('','0');

   close $file;
}


sub out_insertion ($$$) {
   my ($this, $module, $label) = @_;
   return if $label eq '';
   my $file = $this->{file};

   my $object_id = $this->{object}->{label}{id0} ? $this->{object}->{label}{id0} : $this->{object}->{label}{id};


   if ($module) {
      my @param;
      require "$loc::lib_path/$module.pm";
      my $module_name = ($module =~ /\/(.*)/o) ? $1 : $module;
      ($label, @param) = split /\/\//, $label;
#       my $list = [$this, @param];
       my $ban=&{"$module_name\::$label"}($this, @param);
      print $file $ban;
      print $@;
   } elsif ( defined $this->{label}{$label} ) {
      print $file $this->{label}{$label};
   } elsif ( defined $this->{object}->{label}{$label} ) {
      print $file $this->{object}->{label}{$label};
   } elsif ( $this->{object}->can($label) ) {
      print $file eval "\$this->{object}->$label";
      print $@;
   } elsif (-f "$loc::backup_path/$this->{object}->{tpl_name}.$object_id.$label") {
      $this->out_insertion_file("$loc::backup_path/$this->{object}->{tpl_name}.$object_id.$label");
   } elsif (-f "$loc::backup_path/$this->{object}->{tpl_name}.$label") {
       $this->out_insertion_file("$loc::backup_path/$this->{object}->{tpl_name}.$label");
   } else {
      my $tpl_path1 = "$loc::backup_path/$this->{object}->{tpl_name}";
      $tpl_path1 =~ s/[^\/]+$/_/o;
      if (-f "$tpl_path1.$label") {
          $this->out_insertion_file("$tpl_path1.$label");
       } elsif (-f "$tpl_path/_.$label") {
          $this->out_insertion_file("$tpl_path/_.$label");
       }
   }
}


sub out_insertion_file ($$) {

   my ($this, $file0) = @_;
   my $file = $this->{file};
   my $f = new FileHandle;
   my ($ret, $rest, $buf);
   if (open $f, $file0) {
   READING:
      while ($buf = <$f>) {
         if ($buf =~ /<!--abc::/) {
            $rest = $buf;
            while ( $rest =~ s/(.*?)<!--abc::([^:]*)::(.+?)-->//o ) {
               print $file $1;
               $this->out_insertion($2, $3);
            }
            print $file $rest;
         } else {
            print $file $buf;
         }
      }
      close $f;
   }
}

