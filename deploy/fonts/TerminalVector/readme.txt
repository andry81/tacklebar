This is the Terminal (raster) 8x12 font with Unicode support.

Several code pages have been converted from Windows raster font
files (vgaXXX.fon) and merged into a single TrueType font.

Original Terminal fonts are shipped with Windows and copyrighted
as follows:

    (c) Copyright Bitstream Inc. 1984. All rights reserved.
    (c) Copyright Bitstream Inc. 1994. All rights reserved.
    (c)Copyright Microsoft Corp. 1987-95. All Rights Reserved.
    Copyright (c) Computer Logic R&D S.A. - 1994.

vga775 also has a comment:

    Fixed by KADA Satya Ltd.

Some characters have also come from an old ATI video BIOS,
Markus Kuhn's UCS updates to X11 Misc Fixed and Dmitry
Bolkhovityanov's Unicode VGA font.

Vectorized and combined by Jason Hood, inspired by the work of
George Yohng.

    http://terminalvector.adoxa.vze.com/
    http://www.yohng.com/
    http://www.cl.cam.ac.uk/~mgk25/ucs-fonts.html
    http://www.inp.nsk.su/~bolkhov/files/fonts/univga/

Jason Hood disclaims any rights to this font and releases the
vector version into the public domain.


INSTALL
=======

7 onwards:  right-click or open TerminalVector.ttf, Install.
Vista:	    right-click, Install.
XP:	    copy to %windir%\Fonts and either open that folder
	    or refresh it (F5).

To add to Console Properties, open RegEdit to

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont

and add a new string value with one more "0" than the existing
entries (you probably have "0" for "Lucida Console" and "00" for
"Consolas", so add "000").  Set the data to "TerminalVector".

It looks best at sizes 12 or 13 (which is just a copy of 12,
with an extra line at the top).  However, 7 doesn't seem to use
the bitmaps, so just 12 there (although it's possible to patch
conhost.exe to turn off antialiasing...).


COVERAGE
========

Basic Latin			U+0020-U+007E	100%	 95/95
Latin-1 Supplement		U+00A0-U+00FF	100%	 96/96
Latin Extended-A		U+0100-U+017F	100%	128/128
Latin Extended-B		U+0180-U+024F	 10%	 21/208
IPA Extensions			U+0250-U+02AF	 93%	 89/96
Spacing Modifier Letters	U+02B0-U+02FF	 24%	 19/80
Combining Diacritical Marks	U+0300-U+036F	 14%	 16/112
Greek and Coptic		U+0370-U+03FF	 61%	 82/134
Cyrillic			U+0400-U+04FF	 41%	105/256
Armenian			U+0530-U+058F	 99%	 86/87
Hebrew				U+0590-U+05FF	 60%	 52/87
Thai				U+0E00-U+0E7F	100%	 87/87
Georgian			U+10A0-U+10FF	 91%	 80/88
Runic				U+16A0-U+16FF	100%	 81/81
Phonetic Extensions		U+1D00-U+1D7F	  8%	 10/128
Latin Extended Additional	U+1E00-U+1EFF	 38%	 97/256
Greek Extended			U+1F00-U+1FFF	100%	233/233
General Punctuation		U+2000-U+206F	 39%	 43/111
Super and Sub scripts		U+2070-U+209F	100%	 42/42
Currency Symbols		U+20A0-U+20CF	 22%	  6/27
Combining Marks for Symbols	U+20D0-U+20FF	 12%	  4/33
Letterlike Symbols		U+2100-U+214F	 30%	 24/80
Number Forms			U+2150-U+218F	 93%	 54/58
Arrows				U+2190-U+21FF	100%	112/112
Mathematical Operators		U+2200-U+22FF	 43%	109/256
Technical Symbols Misc. 	U+2300-U+23FF	 14%	 35/244
Control Pictures		U+2400-U+243F	 95%	 37/39
Box Drawing			U+2500-U+257F	100%	128/128
Block Elements			U+2580-U+259F	100%	 32/32
Geometric Shapes		U+25A0-U+25FF	100%	 96/96
Symbols Misc.			U+2600-U+267F	 46%	 59/128
Dingbats			U+2700-U+27BF	  0%	  1/191
Math Misc. Symbols-A		U+27C0-U+27EF	 13%	  6/48
Braille Patterns		U+2800-U+28FF	100%	256/256
Symbols and Arrows Supplement	U+2B00-U+2BFF	 52%	 45/87
Latin Extended-C		U+2C60-U+2C7F	  3%	  1/32
Latin Ligatures 		U+FB00-U+FB06	 43%	  3/7
CJK Half Width Forms		U+FF61-U+FF64	100%	  4/4
Katakana Half Width Forms	U+FF65-U+FF9F	100%	 59/59
Specials			U+FFF0-U+FFFD	 20%	  1/5


MANIFEST
========

TerminalVector.sfd	FontForge file
TerminalVector.ttf	the font
TerminalVector.txt	character definitions
txt2sfd.pl		Perl script to convert character
			 definitions to FontForge


============================
Jason Hood, 28 August, 2015.
jadoxa@yahoo.com.au
