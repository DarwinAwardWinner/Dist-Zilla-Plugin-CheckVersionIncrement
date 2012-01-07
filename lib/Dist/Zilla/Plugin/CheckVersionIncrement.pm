## no critic
package Dist::Zilla::Plugin::CheckVersionIncrement;
## use critic
# ABSTRACT: Prevent a release unless the version number is incremented
use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
use Encode qw(encode_utf8);
use LWP::UserAgent;
use version ();
use JSON::PP;

=method before_release

This method checks the version of the dist to be released against the
latest version already indexed on CPAN. If the version to be released
is not greater than the indexed version, it prompts the user to
confirm the release.

This method does nothing if the dist is not indexed at all.

=cut

# Lots of this is cargo-culted from DZP::CheckPrereqsIndexed
sub before_release {
    my ($self) = @_;

    my $pkg = $self->zilla->name;
    $pkg =~ s/-/::/g;
    ### $pkg

    my $pkg_version = version->parse($self->zilla->version);
    my $indexed_version;

    my $ua = LWP::UserAgent->new(keep_alive => 1);
    $ua->env_proxy;
    my $res = $ua->get("http://cpanidx.org/cpanidx/json/mod/$pkg");
    if ($res->is_success) {
        my $yaml_octets = encode_utf8($res->decoded_content);
        my $payload = JSON::PP->new->decode($yaml_octets);
        if (@$payload) {
            $indexed_version = version->parse($payload->[0]{mod_vers});
        }
    }

    if ($indexed_version) {
        return if $indexed_version < $pkg_version;

        my $indexed_description;
        if ($indexed_version == $pkg_version) {
            $indexed_description = "the same version ($indexed_version)";
        }
        else {
            $indexed_description = "a higher version ($indexed_version)";
        }

        return if $self->zilla->chrome->prompt_yn(
            "You are releasing version $pkg_version but $indexed_description is already indexed on CPAN. Release anyway?",
            { default => 0 }
        );
        $self->log_fatal("aborting release because a higher version number is already indexed on CPAN");
    }
    else {
        $self->log("Dist not indexed on CPAN. Skipping check for incremented version.");
    }
}

1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In your F<dist.ini>

    [CheckVersionIncrement]

=head1 DESCRIPTION

This plugin prevents your from releasing a distribution unless it has
a version number I<greater> than the latest version already indexed on
CPAN.

Note that this plugin doesn't check whether your release method
actually involves the CPAN or not. So if you don't use the
UploadToCPAN plugin for releases, then you probably shouldn't use this
one either.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::CheckPrereqsIndexed> - Used as the example for getting the indexed version of a dist
