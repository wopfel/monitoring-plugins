use strict;
use warnings;
use Test::More;

plan tests => 3;

my $output;
my @output;

###

open FILE, ">", "./t/testdata/jsonjq-current.json"  or  die;
my $currentjson = `jo date=\$(date --utc "+%Y-%m-%dT%H:%M:%SZ") otherdata1=some otherdata2=other otherdata3=data`;
print FILE $currentjson;
close FILE  or  die;

$output = `perl ./check_json_jq_timestamp http://localhost:8000/jsonjq-current.json 2>&1`;

is( $?, 0, "Good return code." );
like $output, qr/^OK: younger than/;
like $output, qr/| age=\d+s$/, "Perfdata age having a number";

#print $output;


unlink "./t/testdata/jsonjq-current.json";

