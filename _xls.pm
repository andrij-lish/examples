package xls;

use Win32::OLE;
use _ctrl;
use _fmt;

sub Link            ;
sub Column_name  ($);
sub Worksheet ($$$$);
sub get_param ($$;$);
sub set_param  ($$$);

1;

sub Link {
   $ex = Win32::OLE->GetActiveObject('Excel.Application');
   unless ( $ex ) {
      $ex = Win32::OLE->new('Excel.Application') or die "Excel opening failed. Oops!\n";
      $ex->{Visible} = 1;
   }
   return $ex;
}

sub Worksheet ($$$$) {
   my ($book, $SheetName, $creating, $activate) = @_;
   return undef unless ($book ? $book : $book = Link()->ActiveWorkbook);

   my $sheet0 = $book->ActiveSheet unless $activate;
   my $sheet  = $book->Worksheets($SheetName);
   if ($sheet) {
      if ($creating > 1) {
         $sheet->{Name} = "$SheetName\@".time;
#        !!! may be incorrect !!!
         ($sheet = $book->Worksheets->Add)->{Name} = $SheetName;
      }
   } elsif ($creating) {
      ($sheet = $book->Worksheets->Add)->{Name} = $SheetName;
   }

   $sheet0->Activate if $sheet0;
   return $sheet;
}

sub get_param ($$;$) {
   my ($book, $param, $type) = @_;

   $type = $param unless $type;
   my ($p_name, $tpl) = @{$ctrl::type{$type}};

#   ctrl::info2user ['type',$type], ['$tpl', $tpl];

   my ($p_sheet, $value, $r, $r1, $max_r);
   return undef unless $p_sheet = Worksheet $book, '.param', 1, 0;

   $max_r = $p_sheet->UsedRange->Row + $p_sheet->UsedRange->Rows->Count - 1;
   for ($r = 0; ++$r <= $max_r; ) {
      if (trim $p_sheet->Cells($r, 1)->{Value} eq $param) {
         $r1 = $r;
         last;
      }
   }

   unless ($r1) {
      $r1 = $max_r + 1;
      $p_sheet->Cells($r1, 1)->{NumberFormat} = "@";
   }

   $p_sheet->Cells($r1, 2)->{NumberFormat} = "@";
   $p_sheet->Cells($r1, 1)->{Value} = $param;


   return ( $p_sheet->Cells($r1, 2)->{Value} =~ /$tpl/
          ? $p_sheet->Cells($r1, 2)->{Value}
          : ( $p_sheet->Cells($r1, 2)->{Value} = trim ctrl::get_value $type )
          );

}

sub set_param ($$$) {
   my ($book, $param, $value) = @_;

   my ($p_sheet, $r, $r1, $max_r);
   return unless $p_sheet = Worksheet $book, '.param', 1, 0;

   $max_r = $p_sheet->UsedRange->Row + $p_sheet->UsedRange->Rows->Count - 1;
   for ($r = 0; ++$r <= $max_r; ) {
      if (trim $p_sheet->Cells($r, 1)->{Value} eq $param) {
         $r1 = $r;
         last;
      }
   }
   unless ($r1) {
      $r1 = $max_r + 1;
      $p_sheet->Cells($r1, 1)->{Value} = $param;
   }
   $p_sheet->Cells($r1, 2)->{Value} = $value;
}

sub Column_name ($) {
   my $v    = $_[0] - 1;
   my $base = ord('Z')-ord('A') + 1;
   my $c1   = int ($v / $base);
   my $c2   = $v % $base + 1;
   return ( $c1 ? chr(ord('A') + $c1 - 1) : '').chr(ord('A') + $c2-1)
}

#sub Dump_range ($$$$) {
#   my $range = $_[0];
#   my $r_cnt = $_[1];
#   my $c_cnt = $_[2];
#   open DMP, ">$_[3]";
#   my ($i, $j);
#   for ( $i=0; $i < $r_cnt; $i++ ) {
#      for ( $j=0; $j < $c_cnt; $j++ ) {
#         print DMP $range->[$i][$j], "\t";
#      }
#      print DMP "\n";
#   }
#   close DMP;
#}

#sub open ($) {
#   my $file = $_[0];
#   $ex = Win32::OLE->GetActiveObject('Excel.Application');
#   unless ( $ex ) {
#      $ex = Win32::OLE->new('Excel.Application');
#      return '' unless $ex;
#      $ex->{Visible} = 1;
#   }
#   $file =~ s/\//\\/go;
#   $book = $ex->Workbooks->Open( $file );  
#   return $book;
#}

#sub cells($$$$) {
#   my ($book, $sheet, $r, $c) = @_;
#   if ( ref $sheet 
#   or ( (ref $book or $book = $ex->Workbooks->Open( $book )) and $sheet = $book->WorkSheets->{$sheet})) {    
#      return $sheet->Cells( $r, $c )->{Value};
#   }
#   return '';
#}
