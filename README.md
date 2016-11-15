Subzero
=======

subzero is a small application to build HTTP-stubs fastly.

subzero expects "scroll" file that contains HTTP responses like

     HTTP/1.0 200 OK
     Content-Type: text/plain

     Hello
     $$

Symbol $$ means "end of response". One scroll file can contain multiple answers
splitted by $$. For example


     HTTP/1.0 200 OK
     Content-Type: text/plain

     One
     $$

     HTTP/1.0 200 OK
     Content-Type: text/plain

     Two
     $$

In this case subzero will send responses using round-robin

     One
     Two
     One
     Two
     ...

Run
---

To run subzero with your own scroll you can use

     subzero scroll-file-name 8080

where 8080 is a port's number. Subzero can be runned on *localhost only*.


Docker
------

You can use Docker to build your stubs:

     FROM zasimov/subzero:latest

     ADD scroll.txt /scroll.txt

subzero docker container exposes port 5002 (you can change port using SUBZERO_PORT environment variable).

Also you can pack multiple scrolls 

     FROM zasimov/subzero:latest

     ADD scroll1.txt /scroll1.txt
     # Default scroll
     ADD scroll2.txt /scroll.txt


and choose in runtime

     docker run --rm -ti -eSCROLL=/scroll1.txt my-subzero
