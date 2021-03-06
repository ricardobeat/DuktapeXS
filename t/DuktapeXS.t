use strict;
use warnings;
use JSON;
use utf8;

use Test::More;
use Test::Output;
use Test::Exception;
use Time::HiRes qw(ualarm);

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

sub js_throws {
    my ($code, $cmp) = @_;
    throws_ok sub { js_eval($code); }, $cmp;
}

sub timeout {
    my ($timeout_s, $sub) = @_;
    local $SIG{ALRM} = sub { die "${timeout_s}s timeout triggered"; };
    ualarm ($timeout_s * 1_000_000);
    $sub->();
    ualarm 0;
}

# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------

subtest 'error handling' => sub {
    js_throws q/If you're happy and you know it, Syntax Error!/,
        qr/SyntaxError/;

    js_throws q/this.undefined()/,
        qr/TypeError/;

    js_throws q/new Error('morri');/,
         qr/morri/;

    js_throws q/new EvalError('morri');/,
        qr/EvalError/;

    js_throws q/""--;/,
        qr/ReferenceError/;

    subtest 'error is not printed in output' => sub {
        my $output;
        eval {
            $output = js_eval q/throw new ReferenceError()/;
            fail();
        } or do {
            is($output, undef);
            like($@, qr/ReferenceError/);
        }
    };
};

# -----------------------------------------------------------------------------

subtest 'console stdout' => sub {
    stdout_like sub { js_eval("console.log('YEAAAAAAA');") }, qr/YEAAAAAAA/;
    stdout_like sub { js_eval("console.info('YEAAAAAAA');") }, qr/YEAAAAAAA/;
};

# console.*
subtest 'console stderr' => sub {
    stderr_like sub { js_eval("console.warn('NOOOOOOOO');") }, qr/NOOOOOOOO/;
    stderr_like sub { js_eval("console.error('NOOOOOOOO');") }, qr/NOOOOOOOO/;
};

# -----------------------------------------------------------------------------

subtest 'require' => sub {
    is_js q{
        var test = require('./t/foo');
        test.foo + test.ie5Too0a + test.bark();
    }, 'Hoh6yi5oBARwoof';

    is_js q{
        require('./t/fixtures/shims.js');
        typeof require('./t/fixtures/preact').render;
    }, 'function';

    # thrown error
    js_throws q%var missing = require('./pony');%, qr/cannot find module/;

    # also when last value is an error
    js_throws q%
        try {
            var missing = require('./pony');
        } catch (e) {
            e;
        }
    %, qr/cannot find module/;
};

# -----------------------------------------------------------------------------

subtest 'timeout limit' => sub {
    plan skip_all => 1 if $ENV{FAST};
    diag("\nThis tests use timers, please be patient (set FAST=1 to skip)");

    DuktapeXS::set_timeout(1);

    my $spin = q{
        // gives more opportunity for the scheduler check to run than while(true)
        function F (){ return true };
        var fn = [F];
        while(fn.pop()()) fn.push(F);
        'done';
    };

    dies_ok sub { timeout 0.2 => sub { js_eval_safe($spin); } }, 'Perl should time out first';
    like $@, qr/timeout triggered/;

    lives_ok sub { timeout 2.2 => sub { js_eval_safe($spin); } }, 'Duktape should time out first';

    # dies_ok sub {
    #     timeout 0.2 => sub { js_eval($spin); }
    # }, 'timed out';
    # lives_ok sub { timeout 2.2, sub { isnt js_eval($spin), 'done'; } }, 'Duktape times out first';
};

# -----------------------------------------------------------------------------

subtest 'data payload' => sub {
    my $data = { foo => "bar" };
    is js_eval('DATA.foo', $data), "bar";

    my $thing = { thing => { has => { hashes => [1,2,'c'] } } };
    is js_eval('DATA.thing.has.hashes[1]', $thing), '2';
};

subtest 'calling subs' => sub {
    is js_eval(q/x("abc")/, undef, { x => sub { shift; } }), 'abc', 'shift';
    is js_eval(q/x("abc")/, undef, { x => sub { 123; } }), '123', 'string coercion';
    is js_eval(q/x("abc")/, undef, { x => sub { ref []; } }), 'ARRAY', 'string coercion';
    is js_eval(q/x(typeof x)/, undef, { x => sub { shift; } }), 'function';

    my $data = { foo => "bar" };
    my $subs = { x => sub { my $input = shift; $input . "baz"; } };
    is js_eval(q/x(DATA.foo)/, $data, $subs), "barbaz";

    sub trans {
        my ($tag, $n, $vars) = @_;
        my $tags = {
            hello => {
                0 => 'Hello no one',
                1 => 'Hello {name}',
                2 => 'Hello all {name}'
            }
        };
        $vars = decode_json($vars);
        my $t;
        my $text;
        if ($t = $tags->{$tag}) {
            $text = ($n == 0 ? $t->{0} : $n == 1 ? $t->{1} : $t->{2});
            for my $var (keys %{$vars}) {
                $text =~ s/{$var}/$vars->{$var}/;
            }
            return $text;
        } else {
            return '<missing tag>';
        };
    }

    is js_eval(q/translate('hello', 0, JSON.stringify({ name: 'friends' }))/, undef, {
        translate => \&trans
    }), 'Hello no one';

    is js_eval(q/translate('hello', 1, JSON.stringify({ name: 'you' }))/, undef, {
        translate => \&trans
    }), 'Hello you';

    is js_eval(q/translate('hello', 2, JSON.stringify({ name: 'friends' }))/, undef, {
        translate => \&trans
    }), 'Hello all friends';
};

subtest 'utf8' => sub {
    is js_eval(q/"E aí?"/), "E aí?";
    # TODO: is js_eval(q/"😎"/), "😎";
    is js_eval(q/"Hö"/), "Hö";
    is js_eval(q/
        (function (a){ return a.toUpperCase(); })(DATA.str);
    /, { str => "abc αβγ ß" }), uc("abc αβγ ß");
};

done_testing();
