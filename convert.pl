#!/usr/bin/perl

use strict;
use warnings;

use threads;
use Thread::Queue;

my $threadCount = 10;
my $codecVideo = "h264";
my $codecAudio = "aac";

my $q = Thread::Queue->new();    # A new empty queue
my $log = Thread::Queue->new();
my $doneItem;
my @thr;

for ( 1 .. $threadCount )
{
  $thr[$_] = threads->create(
  sub {
    print("Thread $_ starting\n");
    # Thread will loop until no more work
    while (defined(my $item = $q->dequeue() )) {
      chomp($item);

      my $newName = $item;
      $newName =~ s{\.[^.]*$}{.mp4};
      $newName =~ s/\s/_/g;
      $newName =~ s/input/output/g;

      # Do work on $item
      if(-d $item)
      {
        #print("Thread $_ - File $item is dir\n");
        $item =~ s/input/done/g;
        system("mkdir -p \"$item\"");
        $item =~ s/done/output/g;
        $item =~ s/\s/_/g;
        system("mkdir -p \"$item\"");
      }
      else
      {
        #print("Thread $_ - File $item is file\n");
        print("Thread $_ - ffmpeg -y -nostats -v fatal -i \"$item\" -c:v $codecVideo -c:a $codecAudio \"$newName\" \n");
        system("ffmpeg -y -nostats -v fatal -i \"$item\" -c:v $codecVideo -c:a $codecAudio \"$newName\"");
        system("chmod ugo-w \"$newName\"");
        $doneItem = $item;
        $doneItem =~ s/input/done/g;
        system("mv \"$item\" \"$doneItem\" ");
        print("Thread $_ - finished $item \n");
        $log->enqueue($item);
      }
    }
    print("Thread $_ has no more job, stopping.\n");
    # Join up with the thread when it finishes
  }
  );
}

while (my $line = <>)
{
  #print("Pushing in queue $line \n");
  $q->enqueue($line);
}



my $logger = threads->create(
  sub {
    while (defined(my $item = $log->dequeue() ))
    {
      print("Transcoding finished : $item\nStill in queue : " . $q->pending() . "\n");
    }
  }
);
$q->end();
for ( 1 .. $threadCount )
{
  $thr[$_]->join();
}
$log->end();
$logger->join();
print("Everyone have stopped, exiting.\n");
