package Dist::Zilla::PluginBundle::Author::IOANR;
$Dist::Zilla::PluginBundle::Author::IOANR::VERSION = '0.003';
# ABSTRACT: Build dists the way IOANR likes
use v5.12;
use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy';

# TODO optionally add OSPreqs

sub mvp_multivalue_args {qw/disable assert_os/}

sub configure {
    my ($self) = @_;
    my $arg = $self->payload;

    my $change_opts = {
        exclude_message => '^(dist.ini|v(\d+\.?)+)',
        edit_changelog  => 1,
    };

    if (exists $arg->{semantic_version} && $arg->{semantic_version}) {
        $change_opts->{tag_regexp} = 'semantic';
    }

    $self->add_plugins([
            'Git::GatherDir' => {
                include_dotfiles => 1,
                exclude_match    => '(Changes|README.mkdn)$'
            },
        ],
        [
            'Git::Check' => {
                allow_dirty     => [qw/README.mkdn dist.ini Changes/],
                untracked_files => 'warn',
            }
        ],
        ['PodWeaver'           => {config_plugin => '@Author::IOANR'}],
        ['MetaData::BuiltWith' => {show_config   => 1}],
        [
            ReadmeAnyFromPod => {
                type     => 'markdown',
                filename => 'README.mkdn',
                location => 'root',
            }
        ],
        ['ChangelogFromGit::CPAN::Changes' => $change_opts],
        qw/
          ContributorsFile
          ContributorsFromGit
          ExecDir
          Git::NextVersion
          License
          Manifest
          Meta::Contributors
          MetaJSON
          PkgVersion
          PruneCruft
          RunExtraTests
          ShareDir
          Signature
          Test::CheckDeps
          Test::ReportPrereqs
          TestRelease
          /,
    );

    # Test::Pod::No404s - links are being truncated?
    $self->add_bundle(GitHub => {metacpan => 1});

    # problem with DistManifest and Module::Build::Tiny - _build_params
    $self->add_bundle(
        TestingMania => {
            disable => [
                qw/MetaTests Test::Kwalitee Test::Perl::Critic Test::DistManifest/
            ]});

    if (!$arg->{fake_release}) {
        $self->add_plugins([
                'Git::CommitBuild' => {
                    branch               => '',
                    release_branch       => 'last_release',
                    release_message      => 'Release %v',
                    multiple_inheritance => 1,
                }
            ],
            [
                'Git::Commit' => {
                    allow_dirty => [qw/README.mkdn dist.ini Changes/],
                }
            ],
            ['Git::Tag' => {signed => 1, branch => 'last_release'}],
            qw/
              ConfirmRelease
              Git::Push
              UploadToCPAN
              /
        );
    } else {
        $self->add_plugins(qw/FakeRelease/);
    }

    if (exists $arg->{custom_builder}) {
        $self->add_plugins([
            ModuleBuild => {mb_class => 'My::Builder'},
        ]);
    } else {
        $self->add_plugins('ModuleBuildTiny');
    }

    if (exists $arg->{assert_os}) {
        $self->add_plugins(
            [AssertOS => $self->config_slice({assert_os => 'os'})]);
    }

    if (exists $arg->{disable}) {
        my %plugins = map { $_->[1] => $_ } @{$self->plugins};

        foreach my $plug_to_disable (@{$arg->{disable}}) {
            delete $plugins{"Dist::Zilla::Plugin::$plug_to_disable"};
        }

        my $plugins_ref = $self->plugins;
        @$plugins_ref = values %plugins;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers <ioan@dirtysoft.ca> Sergey Romanov <sromanov-dev@yandex.ru>

=head1 NAME

Dist::Zilla::PluginBundle::Author::IOANR - Build dists the way IOANR likes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Equivalent to the following C<dist.ini>

  [Git::GatherDir]
  include_dotfiles = 1

  [Git::Check]
  allow_dirty = README.mkdn
  allow_dirty = dist.ini
  allow_dirty = Changes

  [PodWeaver]
  config_plugin = @Author::IOANR

  [MetaData::BuiltWith]
  show_config = 1

  [ReadmeAnyFromPod]
  type = markdown
  filename => README.mkdn
  location => build

  [ChangelogFromGit::CPAN::Changes]
  file_name       = Changes
  tag_regexp      = ^v(\d+\.\d+\.\d+)$
  max_age         = 730
  exclude_message = ^(dist.ini|v(\d+\.?)+)
  group_by_author = 1

  [ContributorsFile]
  [ContributorsFromGit]
  [ExecDir]
  [Git::NextVersion]
  [License]
  [Manifest]
  [Meta::Contributors]
  [MetaJSON]
  [ModuleBuildTiny]
  [PkgVersion]
  [PruneCruft]
  [RunExtraTests]
  [ShareDir]
  [Signature]
  [Test::CheckDeps]
  [Test::Pod::No404s]
  [Test::ReportPrereqs]
  [TestRelease]

  [GitHub]
  metacpan = 1

  [TestingMania]
  disable => MetaTests
  disable => Test::Kwalitee
  disable => Test::Perl::Critic

  [Git::CommitBuild]
  release_branch  => 'last_release',
  release_message => 'Release %v',

  [Git::Tag]
  signed = 1
  branch = last_release

  [ConfirmRelease]
  [Git::Commit]
  [Git::Push]
  [UploadToCPAN]

=head1 OPTIONS

=head2 C<fake_release>

Doesn't commit or release anything

  fake_release = 1

=head2 C<disable>

Specify plugins to disable. Can be specified multiple times.

  disable = Some::Plugin
  disable = Another::Plugin

=head2 C<assert_os>

Use L<Devel::AssertOS> to control which platforms this dist will build on.
Can be specified multiple times.

  assert_os = Linux

=head2 C<custom_builder>

If C<custom_builder> is set, L<Module::Build> will be used instead of
L<Module::Build::Tiny> with a custom build class set to C<My::Builder>

=head2 C<semantic_version>

If C<semantic_version> is true (the default), git tags will be in the form
C<^v(\d+\.\d+\.\d+)$>. Otherwise they will be C<^v(\d+\.\d+)$>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues>.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-IOANR/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::IOANR/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR>
and may be cloned from L<git://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
