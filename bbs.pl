#!/usr/bin/env perl
use utf8;

#ｕｔｆ８
use Mojolicious::Lite;
use Mojo::ByteStream qw(b);

use Path::Class qw(file);

app->secret(b(file(__FILE__)->absolute)->md5_sum);

helper data_path => sub {
  return file(__FILE__)->absolute . '.dat';
};

helper get_messages => sub {
  my $data_path = app->data_path;
  my $file      = file($data_path);
  $file->touch;
  return split /\n/, b($file->slurp)->decode(app->renderer->encoding);
};

get '/' => sub {
  shift->redirect_to('index');
};

get '/index' => sub {
  my $self = shift;
  $self->render(messages => [$self->get_messages]);
};

post '/index' => sub {
  my $self     = shift;
  my @messages = $self->get_messages;
  my $msg      = $self->param("msg");
  unshift @messages, $msg;
  my $file_path = $self->data_path;
  my $new_file  = Mojo::Asset::File->new;
  $new_file->add_chunk(
    b(join "\n", @messages)->encode(app->renderer->encoding))
    ->move_to($file_path);
  $self->redirect_to('index');
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'perl入学式 1行掲示板';
%= form_for 'index' => ( method => 'post' ) => begin
%= text_field 'msg'
%= submit_button '投稿する'
<ul>
% for my $msg ( @{$messages} ) {
<li><%= $msg %></li>
% }
</ul>
% end

@@ layouts/default.html.ep
<!doctype html>
<html>
<head>
  <meta charset="<%= app->renderer->encoding %>">
  <title><%= title %></title>
</head>
<body>
<h1><%= title %></h1>
<%= content %>
</body>
</html>
