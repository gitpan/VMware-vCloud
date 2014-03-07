use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "VMware vCloud API",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'VMware::vCloud',
  VERSION  => '2.401',

  PREREQ_PM => {
          'Cache::Bounded' => '1.05',
          'Data::Dumper' => 0,
          'XML::Simple' => 2,
          'LWP' => 5
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'VMware::vCloud::vApp' => {
                                      'version' => '2.401',
                                      'file' => 'lib/VMware/vCloud/vApp.pm'
                                    },
          'VMware::vCloud' => {
                                'version' => '2.401',
                                'file' => 'lib/VMware/vCloud.pm'
                              },
          'VMware::API::vCloud' => {
                                     'version' => '2.401',
                                     'file' => 'lib/VMware/API/vCloud.pm'
                                   }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-VMware-vCloud.git',
                        web  => 'http://github.com/bennie/perl-VMware-vCloud',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=VMware-vCloud',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006001' )
  )

);