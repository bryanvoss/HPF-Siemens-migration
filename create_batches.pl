#!/usr/bin/perl
# bvoss 2008/03/13 Create batches of IERL files for Siemens DI import process
# Lason provided one single directory with over 1 million files(!)

# Config items
$debug = 0;
$verbose = 1;
$dirprefix = "batch-";
$batchsize = 200;
$sourcepath = "/cygdrive/c/temp/IERL";
$targetdir = "/cygdrive/c/temp/target";
# /Config items

if($verbose) {print "Changing to $sourcepath directory\n";}
chdir($sourcepath) || die("Error: cannot cd to $sourcepath\n");
if($verbose) {print "Reading directory listing\n";}
(@dir = <*>) || die("Error: cannot read directory listing from $sourcepath\n");
$filecount = $#dir + 1;
if($verbose) {print "Directory contains $filecount files\n";}

$dircount = 0;
$i = 0;
foreach(@dir) {
	if($debug) {print "In foreach(); dircount=$dircount; i=$i; file=$_\n";}
	if(($dircount == 0) || ($i == $batchsize)) {
		$target = $targetdir . "/" . $dirprefix . $dircount;
		if($verbose) {print "Creating target directory: $target\n";}
		mkdir("$target", 0755) || die("Error: cannot mkdir $target\n");
		$dircount++;
		$i = 0;
	}
	# copy file to target
	$sourcefile = $sourcepath . "/" . $_;
	$targetfile = $target . "/" . $_;
	if($verbose) {print "Copying from: $sourcefile to: $targetfile\n";}
	rename($sourcefile, $targetfile) || die("Error: cannot rename $sourcefile to $targetfile\n");
	if($debug) {print "After rename, file=$_\n";}
	$i++;
}
if($verbose) {print "Finished!\n";}