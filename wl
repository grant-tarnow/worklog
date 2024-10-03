#!/usr/bin/perl

use strict;
use warnings;

my $filename = glob("~/.work_log.csv");

unless ($ARGV[0]) {die "No argument provided. Try 'add'."."\n\n";}

SWITCH:
for ($ARGV[0]) {
	if (/^add/) {
		my $work = getinput("What did you work on?");
		dieonquote($work);
		logwork($filename, $work);
		last SWITCH;
	}
	if (/^today/) {
		my $t = timehash(time());
		report($filename, $t);
		last SWITCH;
	}
	if (/^yest/) {
		my $t = timehash(time() - 86400);
		report($filename, $t);
		last SWITCH;
	}
	if (/^rep/) {
		my $date = getinput("Report on which date? (yyyy-mm-dd)");
		unless ($date =~ /^\d{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$/) {
			die "Error: must enter a valid date (yyyy-mm-dd)."."\n\n";
		}
		my @these = getdate($filename, $date);
		if (scalar(@these) == 0) {
			print "No work entries to report."."\n\n";
		} else {
			foreach my $entry (@these) {
				print "$entry->{date}\t$entry->{time}\t$entry->{msg}"."\n";
			}
		}
		last SWITCH;
	}
	if (/^undo/) {
		my $confirm = getinput("Are you sure you want to delete the last logged work entry? (y/n)");
		if ($confirm eq "y") {
			open(my $fh, "+<", $filename) or die "can't update $filename: $!";
			my $addr;
			while(<$fh>) {
				unless (eof($fh)) { $addr = tell($fh); }
			}
			truncate($fh, $addr) or die "Error: can't truncate $filename: $!";
			close($fh);
			print "Deleted last logged work entry."."\n\n";
		} else {
			print "Didn't delete anything."."\n\n";
		}
		last SWITCH;
	}
	if (/^delete/) {
		print "If you really need to delete a specific record, do in manually. It's just a CSV file: '~/.work_log.csv'."."\n\n";
		last SWITCH;
	}
	if (/^dump/) {
		foreach my $entry (parselog($filename)) {
			print "$entry->{date}\t$entry->{time}\t$entry->{msg}"."\n";
		}
		last SWITCH;
	}
	die "Argument not recognized. Please try again."."\n\n";
}

sub parselog { #filename => array of hashrefs
	my ($filepath) = @_;
	open(my $fh, "<", $filepath) or die "Whoops! Can't find file '$filepath'.\n\n";
	my @entries;
	while (my $line = <$fh>) {
		if ($line =~ /^(\d\d\d\d-\d\d-\d\d),(\d\d:\d\d:\d\d),(.+)$/) {
			my $hashref = {
				date => $1,
				time => $2,
				msg => $3
			};
			push(@entries, $hashref);
		}
	}
	close($fh);
	return @entries;
}

sub getdate { #filename, date => array of hashrefs
	my ($filepath, $date) = @_;
	my @lines = parselog($filepath);
	my @entries;
	foreach my $entry (@lines) {
		if ($entry->{date} eq $date) {
			push(@entries, $entry);
		}
	}
	return @entries;
}

sub getinput { #string => STDOUT, string
	my ($prompt) = @_;
	print $prompt."\n";
	print ">> ";
	my $input = <STDIN>;
	chomp $input;
	print "\n";
	return $input;
}

sub dieonquote { #string
	if ($_[0] =~ /"/) {
		die "No double quotes in your work log!"."\n".
		  "Please try again (single quotes are fine)."."\n\n";
	}

}

sub logwork { # filename, workstring
	my ($filepath, $msg) = @_;
	my $t = timehash(time);
	open(my $fh, ">>", $filepath) or die "Whoops! Can't find file '$filepath'.\n\n";
	my $line = join(",",
		"$t->{year}-$t->{mon}-$t->{mday}",
		"$t->{hour}:$t->{min}:$t->{sec}",
		"\"$msg\"" # the '\"' enquotes the work string
	);
	print $fh $line."\n";
	close($fh);
	print "Logged successfully:"."\n";
	print "$t->{year}-$t->{mon}-$t->{mday}\t$t->{hour}:$t->{min}:$t->{sec}\t$msg"."\n\n";
}

sub timehash { #unixtime => hashref
	my ($unixtime) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
		localtime($unixtime);
	$year += 1900;
	$mon += 1;
	if ($mon < 10) {$mon = "0".$mon;}
	if ($mday < 10) {$mday = "0".$mday;}
	if ($hour < 10) {$hour = "0".$hour;}
	if ($min < 10) {$min = "0".$min;}
	if ($sec < 10) {$sec = "0".$sec;}
	return {
		sec => $sec,
		min => $min,
		hour => $hour,
		mday => $mday,
		mon => $mon,
		year => $year,
		wday => $wday,
		yday => $yday,
		isdst => $isdst
	}
}

sub report { #filepath, hashref => STDOUT
	my ($filepath, $t) = @_;
	my $day = "$t->{year}-$t->{mon}-$t->{mday}";
	my @these = getdate($filepath, $day);
	foreach my $entry (@these) {
		print "$entry->{date}\t$entry->{time}\t$entry->{msg}"."\n";
	}
}
