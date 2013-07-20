package Termomatic;

use Template;

use Dancer2 ':syntax';
use Dancer2::Plugin::Deferred;

our $VERSION = '0.1';

get '/' => sub {
    template 'login' => {
                         failed_login => 1,
                         title => 'Sign-in',
                        };
};

get '/register' => sub {
    
};

true;
