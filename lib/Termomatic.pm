package Termomatic;

use Template;

use Dancer2 ':syntax';
use Dancer2::Plugin::Deferred;

use DateTime;
use DateTime::Format::MySQL;

use DBI;
use Digest::SHA qw'sha1_hex sha512_base64';

our $VERSION = '0.1';

get '/' => sub {
    my $failed_login = param "failed_login" || 0;

    template 'login' => {
                         failed_login => $failed_login,
                         title => 'Sign-in',
                        };
};

post '/register' => sub {
    my $database = quick_connect();

    redirect '/' unless defined(param('user'));

    # generate SHA1 a partir da data concatenada com o email
    my $digest = uc(sha1_hex(param("user") . scalar(localtime)));

    # guardar SHA1, email e timestamp na tabela de confirmações
    # remover outros registos que possam existir referentes ao mesmo email.
    my $sth = $database->prepare("REPLACE INTO user_validate (username, digest) VALUES (?, ?);");
    $sth->execute(param("user"), $digest);

    # enviar email com o SHA1 para confirmação

    template 'message' => {
      title => 'Register',
      message => {
        title => "Registration / Password Recovery",
        text  => "Your registration process is under way. ".
                 "You should be receiving an e-mail with a hyperlink. ".
                 "Follow it to continue your registration or password recovery process."
        },
    };
};

get '/register/validate/:sha' => sub {
    # verificar que o SHA existe e esta up-to-date (1 week)
    # solicitar passowrd e confirmacao de password
    my $database = quick_connect();
    my $sha = param('sha');

    my $sth = $database->prepare("SELECT username, timestamp FROM user_validate WHERE digest = ?");
    $sth->execute($sha);

    my $record = $sth->fetchrow_hashref;

    if ($record && 
        DateTime->now()->
        delta_days(DateTime::Format::MySQL->parse_timestamp($record->{timestamp}))->days< 4)
      {
          template recover => {
                               title => 'Define password',
                               username => $record->{username},
                              };
      } else {
          template message => {
                               title => 'Validate User',
                               message => {
                                           title => 'Error',
                                           text => 'There was an error validating your user. Either you mistype the validation code, or it already expired.' ,
                                          }
                              };
      }
};

post '/register/save' => sub {

    redirect '/' unless defined(param("username")) &&
      defined(param("passA")) && param("passA") eq param("passB");

    my $database = quick_connect();

    my $ins = $database->prepare("INSERT INTO user (username, password) VALUES (?,?)");
    my $del = $database->prepare("DELETE FROM user_validate WHERE username = ?");

    $ins->execute(param("username"), sha512_base64(param("passA")));
    $del->execute(param("username"));

    template message => {
                         title => 'Password Updated',
                         message => {
                                     title => 'Password updated',
                                     text => 'Your password was saved. You can now sign-in.',
                                    }
                        };
};

sub quick_connect {
    my $database = "termomatica";
    my $hostname = "per-fide.di.uminho.pt";
    my $port = 3306;
    my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
    my $dbh = DBI->connect($dsn, 'termomatic', 'termomatic');
    die "Can't connect to database" unless $dbh;
    return $dbh;
}

true;
