# Take the character & bitmap data from TerminalVector.txt, generate a bitmap
# image for each character, trace that image and generate FontForge spline data.
#
# Jason Hood, 8 to 17 October, 2014.
# 25 August, 2015: generate "uniXXXX" names automatically.
#
# According to FontForge, TrueType fonts prefer a power of 2 size, so we'll use
# 2048 - that makes each pixel 2048/12 = 170 em, leaving a margin of 4 top and
# bottom.  However, use 166 em for the width, in order to keep 8 pixels across
# when using a height of 13 lines.
#
# txt2sfd < TerminalVector.txt > TerminalVector.sfd

get_tracer();

$now = time;

# Write the SFD header and info.
  print <<END;
SplineFontDB: 3.0
FontName: TerminalVector
FullName: TerminalVector
FamilyName: TerminalVector
Weight: Regular
Copyright: Released to the public domain. Inspired by the work of George Yohng. Based on the bitmap fonts of Bitstream Inc. (vga850/852/857/863/866/oem, ega80woa), Microsoft Corp. (vga775/855), KADA Satya Ltd. (vga775), Computer Logic R&D S.A. (vga869) and ATI.
Version: 2.1
ItalicAngle: 0
UnderlinePosition: 0
UnderlineWidth: 0
Ascent: 1704
Descent: 344
LayerCount: 2
Layer: 0 1 "Back"  1
Layer: 1 1 "Fore"  0
XUID: [1021 295 18731 817]
FSType: 8
OS2Version: 0
OS2_WeightWidthSlopeOnly: 0
OS2_UseTypoMetrics: 1
CreationTime: $now
ModificationTime: $now
PfmFamily: 49
TTFWeight: 400
TTFWidth: 5
LineGap: 0
VLineGap: 0
Panose: 2 0 5 9 0 0 0 0 0 0
OS2TypoAscent: 0
OS2TypoAOffset: 1
OS2TypoDescent: 0
OS2TypoDOffset: 1
OS2TypoLinegap: 0
OS2WinAscent: 0
OS2WinAOffset: 1
OS2WinDescent: 0
OS2WinDOffset: 1
HheadAscent: 0
HheadAOffset: 1
HheadDescent: 0
HheadDOffset: 1
OS2FamilyClass: 2057
OS2Vendor: 'PfEd'
DEI: 91125
LangName: 1033 "" "" "" "" "" "" "" "" "" "" "" "http://terminalvector.adoxa.vze.com/"
GaspTable: 2 13 1 65535 0 0
Encoding: UnicodeBmp
Compacted: 1
UnicodeInterp: none
NameList: Adobe Glyph List
DisplaySize: -24
AntiAlias: 0
FitToEm: 1
WinInfo: 0 32 16
BeginChars: 65536

END

$update = time;

while (<STDIN>) {
  next if /^\s*(;|$)/;

  # Write the initial character info.
  my ($char, $name, $topline) = split(/\s/);
  $name = 'uni' . substr($char, 2) unless $name =~ /^\w/;
  $code = hex(substr($char, 2));
  print <<END;
StartChar: $name
Encoding: $code $code
Width: 1328
Flags: W
LayerCount: 2
Fore
END

  # Turn the text bitmap into a PBM image, scaled up 3x (the minimum potrace
  # needs to keep the right angles).
  # Map each bitmap, to find duplicates and create references.
  open(PBM, ">glyph.pbm") || die "can't create glyph.pbm";
  binmode PBM;
  print PBM "P4 24 36\n";
  $bits = '';
  $bm13 = '';
  if ($topline =~ /^[.#]/) {
    $topline =~ tr/.#/01/;
    $bm13 = pack 'B8', $topline;
  }
  for ($i = 0; $i < 12; ++$i) {
    $line = <STDIN>;
    $line =~ tr/.#/01/;
    if ($bm13) {
      ($line, $line13) = split(" ", $line);
      $bm13 .= pack 'B8', $line13;
    }
    $bits .= pack 'B8', $line;
    $line =~ s/(.)/\1\1\1/g;
    print PBM pack('B24', $line) x 3;
  }
  close PBM;

  if (not $bm13) {
    # Duplicate the top line for the drawing characters.
    $bm13 = substr($bits, 0, 1) if $code >= 0x2321 and $code < 0x25A0;
    $bm13 .= $bits;
  }

  push @bdf12, $bits;
  push @bdf13, $bm13;
  push @code,  $code;

  if ($chars{$bits}) {
    print "Refer: $chars{$bits} N 1 0 0 1\n";
  }
  else {
    $chars{$bits} = $glyphs . ' ' . $code;
    print "SplineSet\n";
    # The tracer generates anticlockwise points for filled objects, whereas
    # FontForge wants clockwise - reverse each path (not that it really seems
    # to matter).
    @points = ();
    my $start = 0;
    if ($autotrace) {
      open(OUTLINE, "$tracer -background FFFFFF -corner-surround 1 -output-format epd glyph.pbm |");
      while (<OUTLINE>) {
	next if /^%|rg$/;
	($x, $y, $c) = split;
	if (($c eq 'm' and $#points != $start) or /f/) {
	  @points[$start+1..$#points-1] = reverse @points[$start+1..$#points-1];
	  last if /f/;
	  $start = @points;
	}
	push @points, $x / 3 * 166 . ' ' . ($y / 3 - 2) * 170 . " $c 1\n";
      }
    }
    else {
      open(OUTLINE, "$tracer --alphamax 0 --cleartext --unit 0.33 --output - glyph.pbm |");
      while (<OUTLINE>) {
	if (/ i$/) {
	  $start = @points;
	  ($ox, $oy, $x, $y) = split;
	  push @points, $ox * 166 . ' ' . ($oy - 2) * 170 . " m 1\n";
	  $ox += $x; $oy += $y;
	  push @points, $ox * 166 . ' ' . ($oy - 2) * 170 . " l 1\n";
	}
	elsif (/ v$/) {
	  ($x, $y) = split;
	  $ox += $x; $oy += $y;
	  push @points, $ox * 166 . ' ' . ($oy - 2) * 170 . " l 1\n";
	}
	elsif (/^v$/) {
	  @points[$start+1..$#points-1] = reverse @points[$start+1..$#points-1];
	}
      }
    }
    close OUTLINE;

    # FontForge complains about intersecting lines - move points by one em to
    # compensate (but again, it doesn't seem to matter).
    %point = ();
    $start = 0;
    for ($i = 1; $i < @points; ++$i) {
      # The last point of the path is supposed to be the same as the first
      # (just in case it's moved).
      if ($i == $#points or $points[$i+1] =~ /m 1$/) {
	$points[$i] = $points[$start] =~ tr/m/l/r;
	$start = $i + 1;
	next;
      }
      my $p = substr($points[$i], 0, -5);
      if ($point{$p}) {
	($x, $y, $c) = split(" ", $points[$i]);
	my ($x2, $y2) = split(" ", $points[$i + 1]);
	   if ($x > $x2) { --$x; }
	elsif ($x < $x2) { ++$x; }
	elsif ($y > $y2) { --$y; }
	elsif ($y < $y2) { ++$y; }
	$points[$i] = $x . ' ' . $y . " $c 1\n";
      }
      else {
	$point{$p} = 1;
      }
    }
    print join "", @points;
    print "EndSplineSet\n";
  }
  print "EndChar\n\n";
  ++$glyphs;

  if (time != $update) {
    print STDERR "\rGenerating glyphs... $glyphs";
    $update = time;
  }
}
unlink 'glyph.pbm';
print STDERR "\r", ' ' x 26, "\r";

print "EndChars\n\n";

write_bitmap(12);
write_bitmap(13);

print "EndSplineFont\n";


sub write_bitmap {
  my $size = $_[0];
  print "BitmapFont: $size 65536 ", $size - 2, " 2 1\n";
  for (my $i = 0; $i < $glyphs; ++$i) {
    write_bdf($i, $size == 12 ? $bdf12[$i] : $bdf13[$i]);
  }
  print "EndBitmapFont\n\n";
}


sub write_bdf {
  my $left, $right, $bot, $top;
  my $i, $horz, $num;
  my ($glyph, $bits) = @_;
  my $last = length($bits) - 1;
  # Ensure the last line can be expanded to a long for the base85 conversion.
  my @lines = unpack('C*', $bits . "\0\0\0");

  print "BDFChar: $glyph $code[$glyph] 8 ";
  $bot = $last;
  while ($lines[$bot] == 0 and $bot >= 0) { --$bot; }
  if ($bot == -1) {
    print "0 0 0 0\nz\n";
    return;
  }
  $top = 0;
  while ($lines[$top] == 0) { ++$top; }
  $horz = 0;
  for ($i = $top; $i <= $bot; ++$i) { $horz |= $lines[$i]; }
  $left = 0;
  $i = 0x80;
  while (($horz & $i) == 0) { ++$left; $i >>= 1; }
  $right = 7;
  $i = 1;
  while (($horz & $i) == 0) { --$right; $i <<= 1; }
  print "$left $right ", $last - $bot - 2, ' ', $last - $top - 2, "\n";
  for ($i = $top; $i <= $bot; $i += 4) {
    $num  = $lines[$i + 0] << $left << 24;
    $num |= $lines[$i + 1] << $left << 16;
    $num |= $lines[$i + 2] << $left << 8;
    $num |= $lines[$i + 3] << $left << 0;
    print base85($num);
  }
  print "\n";
}

sub base85 {
  my $num = $_[0];
  return "z" if $num == 0;

  my $str = chr(($num % 85) + ord('!'));
  $num = int($num / 85);
  $str = chr(($num % 85) + ord('!')) . $str;
  $num = int($num / 85);
  $str = chr(($num % 85) + ord('!')) . $str;
  $num = int($num / 85);
  $str = chr(($num % 85) + ord('!')) . $str;
  $num = int($num / 85);
  $str = chr(($num % 85) + ord('!')) . $str;

  return $str;
}


sub get_tracer {
  $autotrace = 1;
  $tracer = $ENV{'AUTOTRACE'} || 'autotrace';
  open(my $fh, "$tracer -version 2>nul |");
  if (not <$fh>) {
    $autotrace = 0;
    $tracer = $ENV{'POTRACE'} || 'potrace';
    open($fh, "$tracer -version 2>nul |");
    die "AutoTrace or potrace required" unless <$fh>;
  }
  close $fh;
}
