Dockerize Android5.0 Dev Env
=========================

Dockerized Android5.0 DevEnv (!!! warning: image size ~15GB !!!), contains:

	* Java JDK7
	* android SDK 24.0.1
	* android platforms: android-19 (arm-emulator), android-21 (intel-emulator)
	* NDK r10d
	* android studio 1.0
	* eclipse Luna-SR1
	* ant1.9.4
	* gradle2.1
	* other utilities: firefox, emacs, ruby etc.

allow developing android apps from inside container:

	* run android studio & eclipse from inside containers
	* debug apps on devices connected thru USB
	* mount Workspace (app source code) from host; 
	   allow changing source code from both inside and outside container
	* run as normal user "dev" not root
	* support android 5.0 whose arm based emulator fails at ubuntu, 
	   use intel based emulator which use kvm/qemu.
	* can stop container at any moment, then restart & reattach and pick
	   up work from where left off.
		
different from some other android containers which copies app source into container, 
run gradle build script to build app and then stop & remove container.

Before docker fully support mapping users between host and container, we have to manually
config dev user accounts at host and inside container. So this Dockerfile is not portable,
has to be tuned according to your system, that is why we need this README.

Host setup:

	* ubuntu 14.04
	* install docker 1.3.2 or later
	* add host user account eg. "desktop" (assuming: user-id:1234; group-id:1234)
	* install kvm (assuming: kvm group-id:123, libvirtd group-id:124)
	* add host user account "desktop" to libvirtd group

Build docker image:

	* if your host user/group ids and kvm/libvirtd group-id are different from above,
	    you need change Dockerfile using your user/group ids.
	* sudo docker build -t your-image-name 

Add dot_bashrc content to your .bashrc file and restart.

start android devenv container by running alias "dokdroid":

	alias dokdroid='xdok --name dokdroid -h dokdroid -v ~/Workspace:/home/dev/Workspace --privileged -v /dev/bus/usb:/dev/bus/usb -v /dev/kvm:/dev/kvm -v /var/run/libvirt:/var/run/libvirt your-image-name'

this command will do the following:

	* mount /dev/bus/usb so you can debug app on device thru USB inside container
	* mount /dev/kvm, /var/run/libvirt so you can run intel emulator based on kvm
	* mount ~/Workspace inside container under /home/dev/Workspace

inside container:

	* run as user "dev" with same userid/groupid as host user
	* app source code is under /home/dev/Workspace
	* when you create android5.0 avd, choose "use host gpu".
	* start android studio by running "studio"
	* start eclipse by running "eclipse"

