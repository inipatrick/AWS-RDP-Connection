##Windows AWS RDP Connections

####Back Story
My my new role I found that I often have several RDP connections open to any number of environments at any given time. I wanted to try and simplify this process. 
As well as give me less reasons to open up AWS console. 

###Prep Work 
There is one small part that I've not found a great solution to just yet, but it's setting up the RDP conncetions. 

On line 201 I currently have a directory which will need to be changed and setup for yourself. At the moment I point it to a directory where I have RDP files which contain the username and password for the required environment.

You will need to make sure that you've got your RDP files setup as you'd expect as well as making sure you have a username and password in there. We populate the location and port within line 201 so this shouldn't need to be changed.

Ensure that you've got everything setup for AWS System Manager as well. 

###How to run
You can run this tool in several ways: 

```
 Load it into your faviourte terminal (Obvioulsy Windows Terminal)
    . .\RDPConnection.ps1

 Run it from your editor such as VSCode

 I prefer to make it a part of my Windows Terminal Profile so it's always accessible. 
```
Once you've loaded the code into your terminal then we can start with the following command: 

__Start-AWS || SAWS__ (as the alias to Start-AWS, I just wanted to make it a little faster to access as well as keeping the naming convention of PowerShell).

__SAWS -AWSProfile ProfileName -SearchTerm SERVERName__

This will then go and fetch back all the servers within that AWSProfile as well as limit it to what you've searched for. 

Once the list has been returned you'll be able to quickly glance and see the servers which are online or offline. 

You can then put in the number to the server you wish to connect to. It will then attempt to launch the RPD connection to that server.
