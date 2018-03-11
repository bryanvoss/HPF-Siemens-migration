#!/usr/bin/perl
for($i = 0; $i < 1000; $i++) {
	#print "Creating file $i\n";
	open(OUT, ">IERL/$i");
	print OUT "This is file $i\n";
	close(OUT);
}