requires 'Devel::PatchPerl';
requires 'LWP::Protocol::https';
requires 'YAML::XS';

on 'develop' => sub {
    requires 'Perl::Tidy';
};
