package Filter::Simple::ExportTest;

use Filter::Simple;
use parent qw(Exporter);

our @EXPORT_OK = qw(ok);

FILTER { s/not// };

sub ok { print "ok @_\n" }

1;
