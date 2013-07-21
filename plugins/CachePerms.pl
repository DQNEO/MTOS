package MT::Plugin::CachePerms;
use strict;
use warnings;
use base 'MT::Plugin';

our $VERSION = '1.01';
our $NAME    = ( split /::/, __PACKAGE__ )[-1];

my $plugin = __PACKAGE__->new({
    name        => $NAME,
    id          => lc $NAME,
    key         => lc $NAME,
#    l10n_class  => 'MTCMS::L10N',
    version     => $VERSION,
    author_name => 'SKYARC System Co., Ltd.',
    author_link => 'https://www.skyarc.co.jp/',
    description => '<__trans phrase="Cache permissions for speed-up when using MT 5.1 or later.">',
});
MT->add_plugin( $plugin );

if ( $MT::VERSION >= 5.1 ) {
    my %cache;
    my $overwritten;

    sub init_registry {
        my ( $p ) = @_;
        $p->registry({
            callbacks => {
                init_app     => \&_init_app,
                init_request => {
                    code     => sub { %cache = (); },
                    priority => 6,
                },
            },
        });
    }

    sub _init_app {
        if ( !$overwritten ) {
            require MT::Permission;
            my $orig = \&MT::Permission::perms_from_registry;

            no warnings 'redefine';
            *MT::Permission::perms_from_registry = sub {
                if ( !%cache ) {
                    %cache = %{ $orig->() };
                }
                return \%cache;
            };

            $overwritten = 1;
        }
    }

}

1;
__END__
