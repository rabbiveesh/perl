# https://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=101767
# explicit linking is required to ensure the use of versioned symbols
no strict 'vars';
$::self->{LIBS} = ['-lpthread'] if $Config{libs} =~ /-lpthread/;
