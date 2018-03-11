#!/usr/bin/perl -w
# copy IERL files to batch compiler source directory with failsafes

# *** Config ***
$debug = 0;
$log_file = "/cygdrive/d/SiemensMigration/copy_batches.log";
$source_filesystem = "/cygdrive/y";
$source_filesystem_free = 1048576; # 1 GB free
$arc_filesystem = "/cygdrive/x";
$arc_filesystem_free = 1048576; # 1 GB free
$source_dir = "/cygdrive/y/batchcmp/lason/source";
$max_source_files = 5; # maximum number of files allowed in the source directory
$ierl_batches_dir = "/cygdrive/d/SiemensMigration/IERL.batches";
$ierl_done_dir = "/cygdrive/d/SiemensMigration/IERL.done";
$max_relbatchq_batches = 5; # maximum number of batches allowed in relbatchq
$max_uploadbatchq_batches = 5; # maximum number of batches allowed in uploadbatchq

# database settings
$db_server = "";
$db_username = "";
$db_password = "";
# *** /Config ***

# Set up logging
if($debug) {
	open(LOGFILE, "| tee -ai $log_file");
} else {
	open(LOGFILE, ">> $log_file");
}

# Log session start
logit("*** Session Start ***");

# check free source disk space
$freespace = checkFreeDiskSpace($source_filesystem);
if($freespace < $source_filesystem_free) {
	logit("checkFreeDiskSpace: FAIL: Filesystem ($source_filesystem) less than $source_filesystem_free free");
	logit("*** Session End ***");
	exit;
} else {
	logit("checkFreeDiskSpace: SUCCESS: Filesystem ($source_filesystem) $freespace free");
}

# check number of files in source directory
$numfiles = numFilesInDir($source_dir);
if($numfiles > $max_source_files) {
	logit("numFilesInDir: FAIL: Too many files ($numfiles) in source directory ($source_dir)");
	logit("*** Session End ***");
	exit;
} else {
	logit("numFilesInDir: SUCCESS: $numfiles files in source directory ($source_dir)");
}

# check number of batches in relbatchq
$query = "select count(*) from eiwdata..eiwt_input_queues (nolock) where inq_que_id = 33";
$relbatchq_batches = execQuery($db_server, $db_username, $db_password, "eiwdata", $query);
if($relbatchq_batches > $max_relbatchq_batches) {
	logit("relbatchq: FAIL: Too many batches ($relbatchq_batches) in relbatchq");
	logit("*** Session End ***");
	exit;
} else {
	logit("relbatchq: SUCCESS: $relbatchq_batches batches in relbatchq");
}

# check number of batches in uploadbatchq
$query = "select count(*) from eiwdata..eiwt_input_queues (nolock) where inq_que_id = 32";
$uploadbatchq_batches = execQuery($db_server, $db_username, $db_password, "eiwdata", $query);
if($uploadbatchq_batches > $max_uploadbatchq_batches) {
	logit("uploadbatchq: FAIL: Too many batches ($uploadbatchq_batches) in uploadbatchq");
	logit("*** Session End ***");
	exit;
} else {
	logit("uploadbatchq: SUCCESS: $uploadbatchq_batches batches in uploadbatchq");
}

# check free archive disk space
$freespace = checkFreeDiskSpace($arc_filesystem);
if($freespace < $arc_filesystem_free) {
	logit("checkFreeDiskSpace: FAIL: Filesystem ($arc_filesystem) less than $arc_filesystem_free free");
	logit("*** Session End ***");
	exit;
} else {
	logit("checkFreeDiskSpace: SUCCESS: Filesystem ($arc_filesystem) $freespace free");
}

# check number of subdirectories in IERL.batches directory
$numfiles = numFilesInDir($ierl_batches_dir);
if($numfiles < 1) {
	logit("numFilesInDir: FAIL: No more batches in IERL.batches directory ($ierl_batches_dir)");
	logit("*** Session End ***");
	exit;
} else {
	logit("numFilesInDir: SUCCESS: $numfiles batches in IERL.batches directory ($ierl_batches_dir)");
}

# If we've made it this far, everything looks good. Copy batch to source directory.
# TODO: retrieve list of subdirectories under $ierl_batches_dir and return first entry
(@dir = <$ierl_batches_dir/*>) || die("Error: cannot read directory listing from $ierl_batches_dir\n");
#print "$dir[0]\n";
# copy to $source_dir
logit("Copying files from $dir[0] to $source_dir");
`cp -a $dir[0]/* $source_dir`;
# move to $ierl_done_dir
logit("Moving $dir[0] to $ierl_done_dir");
`mv $dir[0] $ierl_done_dir`;
# That's it. Whee!
logit("BATCH COPIED SUCCESSFULLY");

# Log session end
logit("*** Session End ***");
exit;


sub logit {
	print LOGFILE "[" . localtime(time()) . "] $_[0]\n";
}

sub checkFreeDiskSpace {
	# Retrieve filesystem info from df command
	@df = `df $_[0]`;
	$line = $df[1];
	#logit($line);
	
	# glean value of available column from returned line
	if($line =~ /.:\s*\d*\s*\d*\s*(\d*)/) {
		$freespace = $1;
		#logit("checkFreeDiskSpace: $_[0]: $freespace");
	} else { # line returned was not in expected format, something bad must have happened
		logit("checkFreeDiskSpace: FAIL: Filesystem ($_[0]) not found or info returned in unexpected format");
		exit;
	}
	return($freespace);
}

sub numFilesInDir {
	my $targetdir = $_[0];
	my @files = <$targetdir/*>;
	my $count = @files;
	#if($debug) {logit("count = $count");}
	return($count);
}

# [server], [ username], [ password], [db name], [query]
sub execQuery {
	# call commandline MS SQL client
	@result = `isql -S $_[0] -U $_[1] -P $_[2] -d $_[3] -h-1 -Q "$_[4]"` or die("execQuery: FAIL: Unable to exec isql");
	$line = int($result[0]);
	#logit("execQuery: line = $line");
	# trim leading spaces
	$line =~ s/^\s+//;
	#logit("execQuery: line = $line");
	return($line);
}