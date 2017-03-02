package db;

use _loc;
use _ctrl;
use DBI;

sub new ($);

$exist_connect=();
my @handlers = ();
my @sth_handlers = ();
my %prepared_sth = ();
my $longtime_SQL = 10;
my $max_error_letters = 4;


1;

END {
   my ($h);
   for $h (@sth_handlers) { $h->finish; }
   for $h (@handlers) { $h->disconnect; }
}

sub new ($) {
   my ($db) = @_;

   if ($exist_connect->{$db})
   {
     if($loc::mysql_log)
     {
       open SQL_LOG, ">>$loc::backup_path/_connect_mySQL";
       print SQL_LOG "Connect for $db already exists!\t$0\t\n";
       close SQL_LOG;
     }
     return $exist_connect->{$db};
   }
   else
   {
     my $this = bless {};
     $this->{db_name} = $db;
     $this->{db_name_full} = "DBI:mysql:$db:$loc::db_host{$db}:mysql_local_infile=1";
     $this->{connected} = 0;
     $exist_connect->{$db} = $this;
     return $this;
   }
}

sub get_uniques ($$) {
   my ($this, $table) = @_;
   $this->connect() unless $this->{connected};
   my (@unique, %unique);
   my $index = $this->{dbh}->selectall_arrayref("show index from $table");
   for (@$index) {
      unless ($_->[1]) {
         push @{$unique{$_->[2]}}, $_->[4];
      }
   }
   return [map $unique{$_}, keys %unique];
}

sub get_history_field ($$) {
   my ($this, $table) = @_;
   $this->connect() unless $this->{connected};
   for ( @{$this->{dbh}->selectall_arrayref("explain $table")} ) {
      return $_->[0] if ($_->[0] eq '_history' or $_->[0] eq '_record_history');
   }
   return '';
}

sub do ($$) {
   my ($this, $sql) = @_;
   my ($res,$time,$date);

   if ($loc::mysql_log){
     $time = time;
     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
     $year += 1900;
     $mon   = "0$mon" if ++$mon < 10;
     $mday  = "0$mday" if $mday < 10;
     $date = "$year-$mon-$mday $hour:$min:$sec";
   }

   $this->connect() unless $this->{connected};
#   ctrl::info2user['do', $sql];
   my $dbh = $this->{dbh};
###   return $dbh->do($sql);

   $res = $dbh->do($sql);
   if($loc::mysql_log){
     $time = time - $time;
     $sql =~ s/\n/ /g;
     $sql =~ s/\s+/ /g;
     open SQL_LOG, ">>$loc::backup_path/_log_mySQL";
     print SQL_LOG "$date\t$time\t$sql\t\t$this->{connect_id}\t\n";
     close SQL_LOG;
     if ($time >= $longtime_SQL){
       open SQL_LOG, ">>$loc::backup_path/_log_mySQL_long";
       print SQL_LOG "$date\t$time\t$sql\t$param\t\n";
       close SQL_LOG;
     }
   }
   return $res;
}

sub errstr ($) {
   my ($this) = @_;
   $this->connect() unless $this->{connected};
   return $this->{dbh}->errstr();
}

sub selectrow_array ($$) {
   my ($this, $sql) = @_;
   $this->connect() unless $this->{connected};
#   ctrl::info2user['select', $sql];

#     open file_log, ">>$loc::out_path/sql_error";
#     print  file_log "$sql\n";
#     close file_log;

   return $this->{dbh}->selectrow_array($sql);
}

sub selectall_arrayref ($$) {
   my ($this, $sql) = @_;
   my ($res,$time,$date);
   if ($loc::mysql_log)
   {
     $time = time;
     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
     $year += 1900;
     $mon   = "0$mon" if ++$mon < 10;
     $mday  = "0$mday" if $mday < 10;
     $date = "$year-$mon-$mday $hour:$min:$sec";
   }


   $this->connect() unless $this->{connected};

   $res = $this->{dbh}->selectall_arrayref($sql);
   if($loc::mysql_log)
   {
     $time = time - $time;
     $sql =~ s/\n/ /g;
     $sql =~ s/\s+/ /g;
     open SQL_LOG, ">>$loc::backup_path/_log_mySQL";
     print SQL_LOG "$date\t$time\t$sql\t$param\t$this->{connect_id}\t\n";
     close SQL_LOG;
     if ($time >= $longtime_SQL){
       open SQL_LOG, ">>$loc::backup_path/_log_mySQL_long";
       print SQL_LOG "$date\t$time\t$sql\t$param\t\n";
       close SQL_LOG;
     }
   }

   $res = $this->{dbh}->selectall_arrayref($sql);
   return $res;
}

sub prepare ($$) {
   my ($this, $sql) = @_;
   $this->connect() unless $this->{connected};


   if ($prepared_sth{$sql})
   {
     return $prepared_sth{$sql};
   }

   my $local_sth = sth::new ($this->{dbh}, $sql, $this->{connect_id});
   push @sth_handlers, $local_sth if $local_sth;

   return $local_sth;
}

sub all_tables ($) {
   my ($dbh) = @_;
   my (@row, @ret, $sth);
   ($sth = $dbh->prepare ('show tables'))->execute;
   while (@row = $sth->fetchrow_array) {
      push @ret, $row[0] if $row[0];
   }
   return @ret;
}


sub connect ($$) {
   my ($this) = @_;

   $db = $this->{db_name};
   my $db_user = $loc::db_user{$db} ;
   my $db_pass = $loc::db_pass{$db} ;

#   print "db_user=$db_user, db_pass=$db_pass\n";
#   <STDIN>;
   
   my $h = DBI->connect( $this->{db_name_full}, $db_user, $db_pass );
   if ($h)
   {
     push @handlers, $h;
     $this->{dbh}       = $h;
     $this->{connected} = 1;
     if($loc::mysql_log){
       my $rand = int(rand(100));
       srand();
       $this->{connect_id} = $0."::".time."::".$rand;
       $time = time;
       my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
       $year += 1900;
       $mon   = "0$mon" if ++$mon < 10;
       $mday  = "0$mday" if $mday < 10;
       $date = "$year-$mon-$mday $hour:$min:$sec";
       open SQL_LOG, ">>$loc::backup_path/_connect_mySQL";
       print SQL_LOG "$date\t$0\t\n";
       close SQL_LOG;
     }
     return 1;
   }
   else
   {
     my ($sec,$min,$hour,$day,$month,$year) = localtime;
     $year += 1900;
     ++$month;
     $day = "0".$day if $day =~ /^.$/;
     $month = "0".$month if $month =~ /^.$/;
     $hour = "0".$hour if $hour =~ /^.$/;
     $min = "0".$min if $min =~ /^.$/;
     $sec = "0".$sec if $sec =~ /^.$/;

     open POS, "<$loc::backup_path/error_connect.num";
     $pos=<POS>;
     close POS ;

     if ($pos<=$max_error_letters)
     {
       $pos++;
       open POS, ">$loc::backup_path/error_connect.num";
       print POS $pos;
       close POS ;

       open LETTER, $loc::send_mail;
       print LETTER "To: $mailto\n";
       print LETTER "From: $mailfrom\n";
       print LETTER "Subject: Error in MySQL !!!\n";
       print LETTER "Content-Type: text/plain; charset=windows-1251\n\n";
       print LETTER "Hello!\n\n";
       print LETTER "$year-$month-$day $hour:$min:$sec scrpit $0 produced errors after connect to MySQL!\n";
       print LETTER "Error number: $DBI::err\n";
       print LETTER "Error description: $DBI::errstr\n";
       print LETTER "\nBest regards!\n";
       close LETTER;
     }
   }
}


#############################################################

package sth;
use _loc;
use _ctrl;
use DBI;

sub new ($$$);

1;

sub new ($$$) {
   my ($dbh, $sql, $id) = @_;
   my $this = bless {};
   $this->{prepared} = 0;
   $this->{dbh} = $dbh;
   $this->{sql} = $sql;
   $this->{connect_id} = $id;
   $prepared_sth{$sql} = $this;

   return $this;
}

sub sth_prepare ($) {
   my ($this) = @_;

   unless ($this->{prepared})
   {
     $this->{sth} = $this->{dbh}->prepare($this->{sql});
     $this->{prepared} = 1;
#     open file_log, ">>$loc::out_path/sql_error";
#     print  file_log "$this->{sql}\n";
#     close file_log;
   }
}

sub execute ($@) {
   my ($this,@parameters) = @_;
   my ($res,$param,$time,$date);

   if ($loc::mysql_log){
     $time = time;
     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
     $year += 1900;
     $mon   = "0$mon" if ++$mon < 10;
     $mday  = "0$mday" if $mday < 10;
     $date = "$year-$mon-$mday $hour:$min:$sec";
     $param .= "'$_' " for @parameters;
     $param = "($param)" if $param;
   }

   $this->sth_prepare() unless $this->{prepared};

#   if (@parameters)
#     { return $this->{sth}->execute(@parameters); }
#   else
#     { return $this->{sth}->execute();}

   if (@parameters)
     { $res = $this->{sth}->execute(@parameters); }
   else
     { $res = $this->{sth}->execute();}

   if($loc::mysql_log){
     $time = time - $time;
     $sql =~ s/\n/ /g;
     $sql =~ s/\s+/ /g;
     open SQL_LOG, ">>$loc::backup_path/_log_mySQL";
     print SQL_LOG "$date\t$time\t$this->{sql}\t$param\t$this->{connect_id}\t\n";
     close SQL_LOG;
     if ($time >= $longtime_SQL){
       open SQL_LOG, ">>$loc::backup_path/_log_mySQL_long";
       print SQL_LOG "$date\t$time\t$this->{sql}\t$param\t\n";
       close SQL_LOG;
     }
   }

   return $res;
}

sub fetchrow_array ($) {
   my ($this) = @_;
   $this->sth_prepare() unless $this->{prepared};
   return $this->{sth}->fetchrow_array();
}

sub fetchrow_arrayref ($) {
   my ($this) = @_;
   $this->sth_prepare() unless $this->{prepared};
   return $this->{sth}->fetchrow_arrayref();
}

sub fetchrow_hashref ($) {
   my ($this) = @_;
   $this->sth_prepare() unless $this->{prepared};
   return $this->{sth}->fetchrow_hashref();
}

sub fetchall_arrayref ($) {
   my ($this) = @_;
   $this->sth_prepare() unless $this->{prepared};
   return $this->{sth}->fetchall_arrayref();
}

sub rows ($) {
   my ($this) = @_;
   $this->sth_prepare() unless $this->{prepared};
   return $this->{sth}->rows();
}

sub finish ($) {
   my ($this) = @_;
   return $this->{sth}->finish() if $this->{prepared};
}


