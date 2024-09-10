use strict;
use warnings;
use Test::More;

plan tests => 6;

my $output;
my @output;


###

# Current timestamp should return OK

open FILE, ">", "./t/testdata/jsonjq-current.json"  or  die;
my $currentjson = `jo date=\$(date --utc "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $currentjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/jsonjq-current.json 2>&1`;

is( $?, 0, "Good return code." );
like $output, qr/^OK: younger than/;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";

print "# $output";

unlink "./t/testdata/jsonjq-current.json";


###

# An old timestamp should return WARNING

open FILE, ">", "./t/testdata/jsonjq-old.json"  or  die;
my $oldjson = `jo date=\$(date --utc -d "3 minutes ago" "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $oldjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/jsonjq-old.json 2>&1`;

is( $? >> 8, 1, "Good return code." );
like $output, qr/^WARNING: older than 120 seconds/;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";

print "# $output";

unlink "./t/testdata/jsonjq-old.json";

