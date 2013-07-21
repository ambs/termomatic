package Termomatic;

use Template;

use Dancer2 ':syntax';
use Dancer2::Plugin::Deferred;

our $VERSION = '0.1';

get '/' => sub {
    my $failed_login = param "failed_login" || 0;

    template 'login' => {
                         failed_login => $failed_login,
                         title => 'Sign-in',
                        };
};

post '/register' => sub {

    # generate SHA1 a partir da data concatenada com o email
    # guardar SHA1, email e timestamp na tabela de confirmações
    # remover outros registos que possam existir referentes ao mesmo email.

    # enviar email com o SHA1 para confirmação

    template 'message' => {
                           title => 'Register',
                           message => {
                                       title => "Registration / Password Recovery",
                                       text => "Your registration process is under way. You should be receiving an e-mail with a hyperlink. Follow it to continue your registration or password recovery process."
                                      },
                          };
};

get '/register/validate/:sha' => sub {
    # verificar que o SHA existe e esta up-to-date (1 week)
    # solicitar passowrd e confirmacao de password
    
};

true;
