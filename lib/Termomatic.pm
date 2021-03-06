package Termomatic;

use Template;

use Dancer2;
## use Dancer2::Plugin::Deferred;

use DateTime;
use DateTime::Format::MySQL;

use DBI;
use Digest::SHA qw'sha1_hex sha512_base64';

use Dancer2::Plugin::Emailesque;
use Dancer2::Plugin::Database;

our $VERSION = '0.1';

get '/' => sub {
    if (session("username")) {
        template 'index' => {
                             title => 'Dashboard',
                             projects => get_projects(session('user_id')),
                            };
    }
    else {
        my $failed_login = param "failed_login" || 0;

        template 'login' => {
                             failed_login => $failed_login,
                             title => 'Sign-in',
                            };
    }
};


get '/project/:id/add' => sub {
};

get '/project/new' => sub {
    redirect "/" unless session("username");
    template 'new_project' => {
                               title => 'New Project',
                               languages => available_languages(),
                              };
};

post '/project/save' => sub {
    redirect "/" unless session("username");


    my $target = param("type") eq 'monolingual' ? undef : param("target");
    database->quick_insert( project => { user_id => session('user_id'),
                                         type    => param('type'),
                                         title   => param('name'),
                                         source  => param('source'),
                                         target  => $target });
    forward '/', { }, { method => 'get' };
};


## called for logout
get '/logout' => sub {
    session username => undef;
    redirect '/';
};

## called when user tries to login
post '/login' => sub {
    redirect '/' unless defined(param('user')) && defined(param('pass'));

    my $password = sha512_base64(param('pass'));

    my $sth = database->prepare("SELECT password, user_id FROM user WHERE username = ?");
    $sth->execute(param('user'));
    my $record = $sth->fetchrow_hashref;
    if ($password eq $record->{password}) {
        session username => param('user');
        session user_id  => $record->{user_id};
        return redirect '/';
    } else {
        return forward '/', { failed_login => 1 },  { method => 'get' };
    }

};

## called when user registers
post '/register' => sub {
    redirect '/' unless defined(param('user'));

    # generate SHA1 a partir da data concatenada com o email
    my $digest = uc(sha1_hex(param("user") . scalar(localtime)));

    # guardar SHA1, email e timestamp na tabela de confirmações
    # remover outros registos que possam existir referentes ao mesmo email.
    my $sth = database->prepare("REPLACE INTO user_validate (username, digest) VALUES (?, ?);");
    $sth->execute(param("user"), $digest);

    # enviar email com o SHA1 para confirmação
    email {
            to => param("user"),
            subject => 'Activate your Term-o-Matic account',
            message => 'Please access to '.request->uri_base."/register/validate/$digest to validate and define a new password for your Term-o-Matic account",
           };

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

## Called when the user needs to validate his account
get '/register/validate/:sha' => sub {
    # verificar que o SHA existe e esta up-to-date (1 week)
    # solicitar passowrd e confirmacao de password
    my $sha = param('sha');

    my $sth = database->prepare("SELECT username, timestamp FROM user_validate WHERE digest = ?");
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

## Called after the user accesses with his SHA key and defines a new password.
post '/register/save' => sub {

    redirect '/' unless defined(param("username")) &&
      defined(param("passA")) && param("passA") eq param("passB");


    my $ins = database->prepare("INSERT INTO user (username, password) VALUES (?,?)");
    my $del = database->prepare("DELETE FROM user_validate WHERE username = ?");

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

# sub quick_connect {
#     my $database = "termomatica";
#     my $hostname = "per-fide.di.uminho.pt";
#     my $port = 3306;
#     my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
#     my $dbh = DBI->connect($dsn, 'termomatic', 'termomatic');
#     die "Can't connect to database" unless $dbh;
#     return $dbh;
# }

sub available_languages {
    my $sth = database->prepare("SELECT code, name FROM language;");
    $sth->execute();
    return $sth->fetchall_hashref('code');
}

sub get_projects {
    my $user_id = shift;
    return [ database->quick_select( project => { user_id => $user_id } ) ];
}

true;
