#!./perl

=head postfixderef

this file contains all dereferencing tests from ref.t but using postfix instead of prefix or circumfix syntax.

=cut

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc(qw(. ../lib));
}

plan(128);

{
    note("Test fake references.");
    no strict;

    $baz = "valid";
    $bar = 'baz';
    $foo = 'bar';
    # is ($$$foo, 'valid');
    is ($$foo->$*, 'valid');
    is ($foo->$*->$*, 'valid');
}


{
    note("Test real references.");
    no strict 'vars';
    $FOO = \$BAR;
    $BAR = \$BAZ;
    $BAZ = "hit";
    # is ($$$FOO, 'hit');
    is ($$FOO ->$*, 'hit');
    is ($FOO-> $* ->$*, 'hit');
}

my $test;
{
    note("Test references to real arrays.");

    $test = curr_test();
    my @ary = ($test,$test+1,$test+2,$test+3);
    my @ref;
    $ref[0] = \@main::a;
    $ref[1] = \@main::b;
    $ref[2] = \@main::c;
    $ref[3] = \@main::d;
    for my $i (3,1,2,0) {
        push($ref[$i]-> @*, "ok $ary[$i]\n");
    }
    print @main::a;
    print $ref[1]->[0];
    print $ref[2]->@[0];
    {
        no strict 'refs';
        no strict 'vars';
        print 'd'->@*; # print @{'d'};
    }
}
curr_test($test+4);

{
    note("Test references to references.");
    no strict 'vars';

    $refref = \\$x;
    $x = "Good";
    is ($refref->$*->$*, 'Good'); # is ($$$refref, 'Good');
}


{
    note("Test nested anonymous arrays.");

    my $ref = [[],2,[3,4,5,]];
    is (scalar $ref->@*, 3); # is (scalar @$ref, 3);
    is ($ref->[1], 2); # is ($$ref[1], 2);
    is (${$ref->[2]}[2], 5);
    is ($ref->[2]->[2], 5);
    is ($ref->[2][2], 5);
    is  (scalar $ref->[0]->@*, 0); # is (scalar @{$$ref[0]}, 0);

    is ($ref->[1], 2);
    is ($ref->[2]->[0], 3);

    note("Test references to hashes of references.");

    my $refref;
    { no strict 'vars'; $refref = \%whatever; }
    $refref->{"key"} = $ref;
    is ($refref->{"key"}->[2]->[0], 3);
    is ($refref->{"key"}->[2][0], 3);
    is ($refref->{"key"}[2]->[0], 3);
    is ($refref->{"key"}[2][0], 3);
}


{
    note("Test to see if anonymous subarrays spring into existence.");

    no strict 'vars';
    $spring[5]->[0] = 123;
    $spring[5]->[1] = 456;
    push($spring[5]->@*, 789); # push(@{$spring[5]}, 789);
    is (join(':',$spring[5]->@*), "123:456:789"); # is (join(':',@{$spring[5]}), "123:456:789");

    # Test to see if anonymous subhashes spring into existence.

    $spring2{"foo"}->@* = (1,2,3); # @{$spring2{"foo"}} = (1,2,3);
    $spring2{"foo"}->[3] = 4;
    is (join(':',$spring2{"foo"}->@*), "1:2:3:4");
}

{
    note("Test references to subroutines.");

    my $called;
    our $subref;
    sub mysub { $called++; }
    local $subref = \&mysub;
    &$subref;
    is ($called, 1);
    ok(eval '$subref->&*',"ampersand-star runs coderef: syntax");
    is ($called, 2);
    local *mysubalias;
    ok(eval q{'mysubalias'->** = 'mysub'->**->*{CODE}}, "glob access syntax");
    is ( eval 'mysubalias()', 2);
    is($called, 3);
}
is ref eval {\&{""}}, "CODE", 'reference to &{""} [perl #94476] [gh #11488]';

{
    note("Test references to return values of operators (TARGs/PADTMPs)");

    my @refs;
    for("a", "b") {
        push @refs, \"$_"
    }
    is join(" ", map $_->$*, @refs), "a b", 'refgen+PADTMP';
}

{
    no strict 'vars';
    $subrefref = \\&mysub2;
    is ($subrefref->$*->("GOOD"), "good",
        "Dereferencing a reference to a subroutine reference returns expected value"
    );
    sub mysub2 { lc shift }
}



{
    note("Test anonymous hash syntax.");

    my $anonhash = {};
    is (ref $anonhash, 'HASH', "Reference is to a hash");
    my $anonhash2 = {FOO => 'BAR', ABC => 'XYZ'};
    is (join('', sort values $anonhash2->%*), 'BARXYZ',
        "Dereferencing a hash reference returns expected value"
    );
    $anonhash2->{23} = 'tt';@$anonhash2{skiddoo=> 99} = qw/rr nn/;
    is(join(':',$anonhash2->@{23 => skiddoo => 99}), 'tt:rr:nn', 'pf hash slice');
}

{
    note("Test immediate destruction of lexical objects (op/ref.t tests LIFO order)");

    my $test = curr_test();
    my ($ScopeMark, $Stoogetime) = (1,$test);
    sub InScope() { $ScopeMark ? "ok " : "not ok " }
    sub shoulda::DESTROY  { print InScope,$test++," - Larry\n"; }
    sub coulda::DESTROY   { print InScope,$test++," - Curly\n"; }
    sub woulda::DESTROY   { print InScope,$test++," - Moe\n"; }
    sub frieda::DESTROY   { print InScope,$test++," - Shemp\n"; }
    sub spr::DESTROY   { print InScope,$test++," - postfix scalar reference\n"; }
    sub apr::DESTROY   { print InScope,$test++," - postfix array reference\n"; }
    sub hpr::DESTROY   { print InScope,$test++," - postfix hash reference\n"; }

    {
        no strict 'refs';
        no strict 'vars';
        # and real references taken from symbolic postfix dereferences
        local ($joe, @curly, %larry, $momo);
        my ($s,@a,%h);
        my $woulda = bless \'joe'->$*, 'woulda';
        my $frieda = bless \'momo'->$*, 'frieda';
        my $coulda  = eval q{bless \'curly'->@*, 'coulda' } or print "# $@","not ok ",$test++,"\n";
        my $shoulda = eval q{bless \'larry'->%*, 'shoulda'} or print "# $@","not ok ",$test++,"\n";
        print "# leaving block: we want (larry, curly, moe, shemp)\n";
    }

    print "# left block\n";
    $ScopeMark = 0;
    curr_test($test);
    is ($test, $Stoogetime + 4, "no stooges outlast their scope");
}

{
    no strict 'refs';
    no strict 'vars';
    $name8 = chr 163;
    $name_utf8 = $name8 . chr 256;
    chop $name_utf8;

    is ($name8->$*, undef, 'Nothing before we start');
    is ($name_utf8->$*, undef, 'Nothing before we start');
    $name8->$* = "Pound";
    is ($name8->$*, "Pound", 'Accessing via 8 bit symref works');
    is ($name_utf8->$*, "Pound", 'Accessing via UTF8 symref works');
}

{
    no strict 'refs';
    no strict 'vars';
    $name_utf8 = $name = chr 9787;
    utf8::encode $name_utf8;

    is (length $name, 1, "Name is 1 char");
    is (length $name_utf8, 3, "UTF8 representation is 3 chars");

    is ($name->$*, undef, 'Nothing before we start');
    is ($name_utf8->$*, undef, 'Nothing before we start');
    $name->$* = "Face";
    is ($name->$*, "Face", 'Accessing via Unicode symref works');
    is ($name_utf8->$*, undef,
	'Accessing via the UTF8 byte sequence still gives nothing');
}

{
    no strict 'refs';
    no strict 'vars';
    $name1 = "\0Chalk";
    $name2 = "\0Cheese";

    is ($ $name1, undef, 'Nothing before we start (scalars)');
    is ($name2 -> $* , undef, 'Nothing before we start');
    $name1 ->$*  = "Yummy";
    is ($name1-> $*, "Yummy", 'Accessing via the correct name works');
    is ($$name2, undef,
	'Accessing via a different NUL-containing name gives nothing');
    # defined uses a different code path
    ok (defined $name1->$*, 'defined via the correct name works');
    ok (!defined $name2->$*,
	'defined via a different NUL-containing name gives nothing');

    my (undef, $one) = $name1 ->@[2,3];
    my (undef, $two) = $name2-> @[2,3];
    is ($one, undef, 'Nothing before we start (array slices)');
    is ($two, undef, 'Nothing before we start');
    $name1->@[2,3] = ("Very", "Yummy");
    (undef, $one) = $name1 -> @[2,3];
    (undef, $two) = $name2 -> @[2,3];
    is ($one, "Yummy", 'Accessing via the correct name works');
    is ($two, undef,
	'Accessing via a different NUL-containing name gives nothing');
    ok (defined $one, 'defined via the correct name works');
    ok (!defined $two,
	'defined via a different NUL-containing name gives nothing');

}


{
    note("Test dereferencing errors");

    format STDERR =
.
    my $ref;
    foreach $ref (*STDOUT{IO}, *STDERR{FORMAT}) {
    	eval q/ $ref->$* /;
    	like($@, qr/Not a SCALAR reference/, "Scalar dereference");
    	eval q/ $ref->@* /;
    	like($@, qr/Not an ARRAY reference/, "Array dereference");
    	eval q/ $ref->%* /;
    	like($@, qr/Not a HASH reference/, "Hash dereference");
    	eval q/ $ref->() /;
    	like($@, qr/Not a CODE reference/, "Code dereference");
    }

    $ref = *STDERR{FORMAT};
    eval q/ $ref->** /; # postfix GLOB dereference ?
    like($@, qr/Not a GLOB reference/, "Glob dereference");

    $ref = *STDOUT{IO};
    eval q/ $ref->** /;
    is($@, '', "Glob dereference of PVIO is acceptable");

    is($ref, (eval '$ref->*{IO}'), "IO slot of the temporary glob is set correctly");
}

TODO: {
    no strict 'vars';
    # these will segfault if they fail
    sub PVBM () { 'foo' }
    my $pvbm_r;
    ok(eval q/ $pvbm_r = \'PVBM'->&* /, "postfix symref to sub name");
    is("$pvbm_r", "".\&PVBM, "postfix and prefix mechanisms provide same result");
    my $pvbm = PVBM;
    my $rpvbm = \$pvbm;
    {
        my $SynCtr;
        ok (!eval q{ $SynCtr++; $rpvbm->** }, 'PVBM ref is not a GLOB ref');
        ok (!eval q{ $SynCtr++; $pvbm->** }, 'PVBM is not a GLOB ref');
        is ($SynCtr, 2, "starstar GLOB postderef parses");
    }
    ok (!eval { $pvbm->$* }, 'PVBM is not a SCALAR ref');
    ok (!eval { $pvbm->@* }, 'PVBM is not an ARRAY ref');
    ok (!eval { $pvbm->%* }, 'PVBM is not a HASH ref');
}

{
    note("Test undefined hash references as arguments to %{} in boolean context");
    note('[perl #81750] [gh #10947]');
    no strict 'refs';
    eval { my $foo; $foo->%*;             }; ok !$@, '%$undef';
    eval { my $foo; scalar $foo->%*;      }; ok !$@, 'scalar %$undef';
    eval { my $foo; !$foo->%*;            }; ok !$@, '!%$undef';
    eval { my $foo; if ( $foo->%*) {}     }; ok !$@, 'if ( %$undef) {}';
    eval { my $foo; if (!$foo->%*) {}     }; ok !$@, 'if (!%$undef) {}';
    eval { my $foo; unless ( $foo->%*) {} }; ok !$@, 'unless ( %$undef) {}';
    eval { my $foo; unless (!$foo->%*) {} }; ok !$@, 'unless (!%$undef) {}';
    eval { my $foo; 1 if $foo->%*;        }; ok !$@, '1 if %$undef';
    eval { my $foo; 1 if !$foo->%*;       }; ok !$@, '1 if !%$undef';
    eval { my $foo; 1 unless $foo->%*;    }; ok !$@, '1 unless %$undef;';
    eval { my $foo; 1 unless ! $foo->%*;  }; ok !$@, '1 unless ! %$undef';
    eval { my $foo;  $foo->%* ? 1 : 0;    }; ok !$@, ' %$undef ? 1 : 0';
    eval { my $foo; !$foo->%* ? 1 : 0;    }; ok !$@, '!%$undef ? 1 : 0';
}

# Postfix key/value slices
is join(" ", {1..10}->%{1, 7, 3}), "1 2 7 8 3 4", '->%{';
is join(" ", ['a'..'z']->%[1, 7, 3]), "1 b 7 h 3 d", '->%[';

{
    no strict 'vars';

    note("Array length");

    is [1..10]->$#*, 9, 'rvalue ->$#*';
    @foo = 1..10;
    (\@foo)->$#*--;
    is "@foo", "1 2 3 4 5 6 7 8 9", 'lvalue ->$#*';

    note("Interpolation");

    $_ = "foo";
    @foo = 7..9;
    %foo = qw( foo oof );
    is "$_->@*", 'foo->@*', '->@* does not interpolate without feature';
    is "$_->@[0]", 'foo->@[0]', '->@[ does not interpolate without feature';
    is "$_->@{foo}", "foo->7 8 9", '->@{ does not interpolate without feature';

    {
        use feature 'postderef_qq';
        no strict 'refs';
        $foo = 43;
        is "$_->$*", "43", '->$* interpolated';
        is "$_->$#*", "2", '->$#* interpolated';
        is "$_->@*", "7 8 9", '->@* interpolated';
        is "$_->@[0,1]", "7 8", '->@[ interpolated';
        is "$_->@{foo}", "oof", '->@{ interpolated'; # }
        is "foo$_->$*bar", "foo43bar", '->$* interpolated w/other stuff';
        is "foo$_->@*bar", "foo7 8 9bar", '->@* interpolated w/other stuff';
        is "foo$_->@[0,1]bar", "foo7 8bar", '->@[ interpolated w/other stuff';
        is "foo$_->@{foo}bar", "foooofbar", '->@{ interpolated w/other stuff'; # }
        is "@{[foo->@*]}", "7 8 9", '->@* inside "@{...}"';
        is "@{[foo->@[0,1]]}", "7 8", '->@[ inside "@{...}"';
        is "@{[foo->@{foo}]}", "oof", '->@{ inside "@{...}"'; # }

        # "foo $_->$*" should be equivalent to "foo $$_", which uses concat
        # overloading
        package o {
    	use overload fallback=>1,
    	    '""' => sub { $_[0][0] },
    	    '.'  => sub { bless [ "$_[$_[2]]"." plus "."$_[!$_[2]]" ] };
        }
        my $o = bless ["overload"], o::;
        my $ref = \$o;
        is "foo$ref->$*bar", "foo plus overload plus bar",
           '"foo $s->$* bar" does concat overloading';
    }
}

# parsing of {} subscript as subscript rather than block
{
    sub ppp { "qqq" }
    my $h = { ppp => "pp", qqq => "qq", rrr => 7 };
    is ${$h}{ppp}, "pp";
    is ${$h}{"rrr"} - 2, 5;
    my $ar = [$h];
    is $ar->[0]->{ppp}, "pp";
    is $ar->[0]->{"rrr"} - 2, 5;
    is $ar->[0]{ppp}, "pp";
    is $ar->[0]{"rrr"} - 2, 5;
    my $hr = {h=>$h};
    is $hr->{"h"}->{ppp}, "pp";
    is $hr->{"h"}->{"rrr"} - 2, 5;
    is $hr->{"h"}{ppp}, "pp";
    is $hr->{"h"}{"rrr"} - 2, 5;
    my $cr = sub { $h };
    is $cr->()->{ppp}, "pp";
    is $cr->()->{"rrr"} - 2, 5;
    is $cr->(){ppp}, "pp";
    is $cr->(){"rrr"} - 2, 5;
}
