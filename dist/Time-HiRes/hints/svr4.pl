# NCR MP-RAS needs to explicitly link against libc to pull in usleep
# what's the reason for -lm?
no strict 'vars';
$self->{LIBS} = ['-lm', '-lc'];

