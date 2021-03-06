# myfitnesspal
* Instructions on how to compile your service:

This is a PERL script. No compilation is necessary.  If you really want to, you can see a working version by telnetting to port 3000 on a server running out of my home.  Do it like this:

<PRE>adomingo@adomingo-4907: ~/Desktop/myfitnesspal $ telnet 24.130.132.117 3000
Trying 24.130.132.117...
Connected to c-24-130-132-117.hsd1.ca.comcast.net.
Escape character is '^]'.
GET /chat/1 HTTP/1.0

HTTP/1.1 200 OK
Date: Tue, 04 Sep 2018 21:46:27 GMT
Content-Length: 365
Content-Type: text/html;charset=UTF-8
Server: Mojolicious (Perl)

{
   "1535844846" : {
      "text" : "This is a test.",
      "expiration_date" : "Sat Sep  1 16:35:06 2018"
   },
   "1535844855" : {
      "expiration_date" : "Sat Sep  1 16:35:00 2018",
      "text" : "blah blah"
   },
   "1535947138" : {
      "expiration_date" : "Sun Sep  2 21:19:32 2018",
      "text" : "here's another test"
   },
   "id" : 1
}
Connection closed by foreign host.
adomingo@adomingo-4907: ~/Desktop/myfitnesspal $</PRE>

* Instructions on how to run your service locally:

Most linux systems come with PERL. So using a Linux machine to run it is highly preferred (by me). It might work on a windows machine but I haven't tested it and a PERL interpreter needs to be installed, etc.  Simply explode the tarball and just run the script as yourself by typing something like "perl ./simulation_problem.pl". There is no need to be root.

Actually the script assumes that the json database file is in your home directory.  So you might want to explode this to your home directory on whatever linux machine this is being run on

* The decisions you made:

I decided to use mojolicious to make my life easier.  It's just a bunch of PERL modules that create the websocket for me and a bunch of other stuff.  Although I write PERL scripts a lot, I've never actually used this before, so this project was very enlightening for me.  You can read about mojolicious here: https://mojolicious.org/

I also decided to use the JSON module available on CPAN because I didn't feel like writing out all the json.

It's also a hybrid of function oriented and object oriented code.  There are people in this world that hate that PERL allows you to do this.  But I was in a rush.

* The limitations of your implementation:

I set it to be able to create a max of 100 users but that can easily be extended.  That number is hardcoded because I was in a rush.  There's also the possibility of a race condition if millions of people start using this at the same time.  A couple of them might get the same userid and then who knows what'll happen.

It also uses a file for a database.  But if for an actual production system we probably want a REAL database.  Since no transactions are going to be taking place I'd probably go with a NoSQL database like Cassandra but that's just me.

* What you would do if you had more time:

Well, as I previously mentioned, there's this race condition.  It should be extremely rare, and since this is only for an assessment it's probably never going to be an issue.  But if I intended to open this up to the whole world then I'd probably fix that.

Also, the script doesn't give you any (friendly) errors. If all the chats for a user has expired and then you try to get all the chats for that user it happily responds with just a userid and nothing else.  I'd probably devote some time to informative messages if I could.

* How you would scale it in the future:

Well, for starters, I'd fix that race condition.  Then probably get the chats to start getting written to a database instead of a json file.  Then maybe make that a NOSQL database for the performance.  Then maybe make that a clustered NOSQL database like Cassandra.  And then decide how to containerize this stuff and migrate to the cloud like how my current company is doing.
