use inc::Module::Install;
name 'Twitter-Reader';
all_from 'lib/Twitter/Reader.pm';

requires 'Net::Twitter';
requires 'URI::Find';
requires 'Web::Scraper';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
