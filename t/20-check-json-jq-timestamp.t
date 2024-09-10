use strict;
use warnings;
use Test::More;

plan tests => 12;

my $output;
my @output;
my $filename;


###

# Current timestamp should return OK

$filename = "jsonjq-current.json";

open FILE, ">", "./t/testdata/$filename"  or  die;
my $currentjson = `jo date=\$(date --utc "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $currentjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/$filename 2>&1`;

is( $?, 0, "Good return code." );
like $output, qr/^OK: younger than/;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";
like $output, qr/| age=[0-5]s$/, "Perfdata should return less or equal 5 seconds";

print "# $output";

unlink "./t/testdata/$filename";


###

# An old timestamp should return WARNING

$filename = "jsonjq-old.json";

open FILE, ">", "./t/testdata/$filename"  or  die;
my $oldjson = `jo date=\$(date --utc -d "3 minutes ago" "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $oldjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/$filename 2>&1`;

is( $? >> 8, 1, "Good return code." );
like $output, qr/^WARNING: older than 120 seconds/;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";
like $output, qr/| age=18\ds$/, "Perfdata should return about 180 seconds";

print "# $output";

unlink "./t/testdata/$filename";


###

# A very old timestamp should return CRITICAL

$filename = "jsonjq-veryold.json";

open FILE, ">", "./t/testdata/$filename"  or  die;
my $oldjson = `jo date=\$(date --utc -d "2 days ago" "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $oldjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/$filename 2>&1`;

is( $? >> 8, 2, "Good return code." );
like $output, qr/^CRITICAL: older than 1 hour: /;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";
like $output, qr/| age=17280\ds$/, "Perfdata should return about 172800 seconds";

print "# $output";

unlink "./t/testdata/$filename";

