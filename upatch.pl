#!/usr/bin/perl

use v5.20;
use strict;
use warnings;

use Path::Tiny;
use IO::Pipe;

# upatch - the universal/user-friendly/unified/utilitarian patch editor, a package porter's patching pal, in Perl
# Copyright 2020 Stephen Cavilia
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.


my ($cmd, @args) = @ARGV;

my $project_root;
my $state_dir;
my @diffopts = qw(-u5 -d -p);

# walk up the tree to find a .upatch directory
sub find_root {
    my $dir = Path::Tiny::cwd;
    while (!($dir->child('.upatch')->is_dir))
    {
        if ($dir eq $dir->parent)
        {
            say "No upatch state directory found, reached $dir";
            return undef;
        }
        else
        {
            $dir = $dir->parent;
        }
    }
    $project_root = $dir;
    $state_dir = $dir->child('.upatch');

    return $project_root;
}

# create .upatch in the current directory
sub init {
    $project_root = Path::Tiny::cwd;
    $state_dir = $project_root->child('.upatch');
    $state_dir->mkpath;
    die unless $state_dir->is_dir;
    say "Created $state_dir";
}

# edit a file, preserving the original
sub edit {
    my @files = @_;

    for my $path(@files)
    {
        my $file = Path::Tiny::cwd->child($path)->realpath;
        my $rel = $file->relative($project_root);
        #say "Relative path: $rel";
        my $orig = $state_dir->child('base')->child($rel);
        #say "Backup original: $orig";
        if (!$orig->exists)
        {
            $orig->parent->mkpath;
            say "Preserving original as $orig";
            $file->copy($orig);
        }

        say "Editing $file";
        run_editor($file);

        say "No changes made to $rel"
          unless (show_diff($file));
    }
}

# call the user's editor program to edit a file
sub run_editor {
    my $file = shift;

    if (defined $ENV{EDITOR})
    {
        system($ENV{EDITOR}, $file);
    }
    else
    {
        say "Please set \$EDITOR!";
    }
}

# show the changes for a given file
sub show_diff {
    my $file = shift;

    my $rel = $file->relative($project_root);
    my $orig = $state_dir->child('base')->child($file->relative($project_root));

    #say "diffing $orig <-> $file";

    # format the correct relative paths
    my $a = path('a')->child($rel);
    my $b = path('b')->child($rel);

    # call diff(1)
    my @difflines;
    {
        my $diff = IO::Pipe->new();
        $diff->reader('diff', @diffopts, $orig, $file);
        @difflines = <$diff>;
    }

    if (@difflines > 0)
    {
        # output the modified a/b header and the diff body
        say "--- $a";
        say "+++ $b";
        print @difflines[2..$#difflines];
        return 1;
    }
    else
    {
        # display nothing but return 0
        return 0;
    }
}

# show all changes in the project
sub diff_all {
    my $base = $state_dir->child('base');
    my $iter = $base->iterator({recurse => 1});
    while (my $path = $iter->())
    {
        show_diff($project_root->child($path->relative($base)))
          if $path->is_file;
    }
}


unless (defined $cmd)
{
    say "Usage: $0 <command>";
    exit 2;
}

if ($cmd eq 'init')
{
    init();
}
else
{
    # all non-init commands need an intialized project
    if (defined find_root())
    {
        #say "Project: $project_root";
        if ($cmd eq 'edit')
        {
            edit(@args);
        }
        elsif ($cmd eq 'diff')
        {
            if (@args)
            {
                show_diff path($_) for @args;
            }
            else
            {
                diff_all();
            }
        }
        else
        {
            say "Unknown command $cmd";
            exit 2;
        }
    }
    else
    {
        say "No project state directory found";
        exit 1;
    }
}
