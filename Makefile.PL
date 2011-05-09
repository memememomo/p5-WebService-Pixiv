use inc::Module::Install;
name 'WebService-Pixiv';
all_from 'lib/WebService/Pixiv.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
