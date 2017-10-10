use strict;
use warnings;
use Data::Dumper;

use Test::More;
BEGIN { use_ok('DuktapeXS') };

use DuktapeXS qw(:all);

sub print_bytes {
    my $str = shift;
    my $bytes = "";
    foreach my $ch (split('', $str)) {
        $bytes .= sprintf("%x ", ord($ch));
    }
    return $bytes;
}

sub is_js {
    my ($code, $cmp) = @_;
    is(js_eval($code), $cmp);
}

# Some basic sanity tests
subtest 'Maths' => sub {
    is_js q/7 * 7/, "49";
    is_js q/2 + 7/, "9";
    is_js q/10 * 1e5 + 0.77/, 1000000.77;
};

subtest 'Arrays' => sub {
    is_js q/["bacon", "burger"].join(' ')/, 'bacon burger';
    is_js q/[1,2,3,4,5,6,7].length/, 7;
    is_js q/typeof []/, 'object';
    is_js q/Object.prototype.toString.call([])/, '[object Array]';
};

subtest 'Object' => sub {
    is(js_eval(q{typeof {}}), 'object');
    is(js_eval(q{Object.prototype.toString.call({})}), '[object Object]');
    is(js_eval(q{var _ = 99, x = { a: _ }; x.a}), '99');
};

done_testing();
