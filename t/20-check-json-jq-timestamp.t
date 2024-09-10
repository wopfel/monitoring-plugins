use strict;
use warnings;
use Test::More;

plan tests => 6;

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

print "# $output";

unlink "./t/testdata/$filename";

