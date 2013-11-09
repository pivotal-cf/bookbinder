# Bookbinder

Bookbinder is a gem that binds together a unified documentation web-app from disparate source material, stored as repositories of markdown on GitHub. It runs middleman to produce a (CF-pushable) Sinatra app.

## About

Bookbinder is meant to be used from within a "book" project. The book project provides a configuration of which documentation repositories to pull in; the bookbinder gem provides a set of scripts to aggregate those repositories and publish them to various locations. It also provides script geared towards running a CI system that can verify that your book is free of any dead links.

## Setting Up a Book Project

A book project needs a few things to allow bookbinder to run. Here's the minimal directory structure you need in a book project:

```
.
├── Gemfile
├── Gemfile.lock
├── .ruby-version
├── config.yml
└── master_middleman
    ├── config.rb
    └── source
        └── index.html.md
```

`Gemfile` needs to point to this bookbinder gem, and probably no other gems. `Gemfile.lock` can be created by bundler automatically (see below).

Bookbinder uses bundler and we recommend installing [rbenv](https://github.com/sstephenson/rbenv). WARNING: If you install rbenv, you MUST uninstall RVM first (http://robots.thoughtbot.com/post/47273164981/using-rbenv-to-manage-rubies-and-gems).

Once rbenv is set up and the correct ruby version is set up (2.0.0-p195), run (in your book project)

    gem install bundler
    bundle

And you should be good to go!


Bookbinder's main entry point is the `bookbinder` executable. The following commands are available:

### `publish`

Bookbinder's most important command is `publish`. It takes one argument on the command line:

        bookbinder publish local

will find documentation repositories in directories that are siblings to your current directory, while

        bookbinder publish github

will find doc repos by downloading the latest version from github.

The publish command creates 2 output directories, one named `output/` and one named `final_app/`. These are placed in the current directory and are cleared each time you run bookbinder. Both are ignored by git.

`final_app/` contains bookbinder's ultimate output: a Sinatra web-app that can be pushed to cloud foundry or run locally.

`output/` contains intermediary state, including the final prepared directory that the `publish` script ran middleman against, in `output/master_middleman`.
