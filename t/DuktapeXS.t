use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Output;
use Test::Exception;

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

sub timeout {
    my ($timeout, $sub) = @_;
    local $SIG{ALRM} = sub { die "timed out\n" }; # NB: \n required
    alarm $timeout;
    $sub->();
    alarm 0;
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
    is_js q/typeof {}/, 'object';
    is_js q/Object.prototype.toString.call({})/, '[object Object]';
    is_js q/var _ = 99, x = { a: _ }; x.a/, '99';
};

subtest 'Error' => sub {
    like js_eval("syntax error!"), qr/SyntaxError/;
    like js_eval("this.undefined()"), qr/TypeError/;
};

subtest 'console stdout' => sub {
    stdout_like sub { js_eval("console.log('YEAAAAAAA');") }, qr/YEAAAAAAA/;
    stdout_like sub { js_eval("console.info('YEAAAAAAA');") }, qr/YEAAAAAAA/;
};

subtest 'console stderr' => sub {
    stderr_like sub { js_eval("console.warn('NOOOOOOOO');") }, qr/NOOOOOOOO/;
    stderr_like sub { js_eval("console.error('NOOOOOOOO');") }, qr/NOOOOOOOO/;
};

subtest 'require' => sub {
    is_js q{
        var test = require('./t/foo');
        test.foo + test.ie5Too0a + test.bark();
    }, 'Hoh6yi5oBARwoof';
};

subtest 'timeout check' => sub {
    DuktapeXS::set_timeout(1);
    my $spin = q/while (true) 1; 'unreachable';/;
    dies_ok sub { timeout 1, sub { isnt js_eval($spin), 'unreachable'; } }, 'Duktape timeout reached';
    lives_ok sub { timeout 2, sub { isnt js_eval($spin), 'unreachable'; } }, 'Duktape timeout not reached';
};

done_testing();
