#how to setup environment

Note: if you are using windows please enable virtualization in your bios. to be able to run this project

##step01> clone devbox vagrant box
1. install virtual machine 6.0.14 minimum
2. install vagrant from https://www.vagrantup.com/downloads.html (for windows download 32bit even if you have 64bit machine) min version 2.2.6
3. clone devbox repository git@github.com:mshadloo22/prototype.net-devbox.git into folder prt

##step02> clone src into source folders run this commands:

>>cd prt/src

>>clone git@github.com:mshadloo22/prototype.net.testcode-api.git api

>>clone git@github.com:mshadloo22/prototype.net.testcode-frontend.git frontend



##step03> run vagrant
>>vagrant up









Url for frontend: http://192.168.123.110/prt/
url for admin: http://192.168.123.110/prt/admin/

url for api: http://192.168.123.110/prt/api/    
(my convention http://192.168.123.110/prt/api/Controllername/functionname e.g  http://192.168.123.110/prt/api/Default/test)
