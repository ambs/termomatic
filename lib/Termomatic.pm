package Termomatic;
use Template;
use Dancer2 ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'login' => {
                         title => 'Sign-in',
                        };
};

true;
