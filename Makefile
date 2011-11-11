Ball: installed java3d plugin_archives all
include $(shell rospack find mk)/cmake.mk

INSTALL_DIR=`rospack find openhrp3`
HG_DIR = build/openhrp-aist-grx-svn
HG_URL = https://openhrp-aist-grx.googlecode.com/hg/
HG_PATCH =patch/PD_HGtest.xml.patch patch/Sample.xml.patch patch/SampleHG.xml.patch patch/SampleLF.xml.patch patch/SamplePD.xml.patch patch/SamplePD_HG.xml.patch patch/SampleSV.xml.patch
#HG_REVISION=@REVISION@
include $(shell rospack find mk)/hg_checkout.mk

# https://code.ros.org/trac/ros/ticket/3748
$(HG_DIR):
	mkdir -p `dirname $(HG_DIR)`; hg clone $(HG_URL) $(HG_DIR)
	cd $(HG_DIR) && hg update $(HG_BRANCH) && hg update $(HG_REVISION)
	touch rospack_nosubdirs

check-java-version:
	@if [ ! "`java -version 2>&1 | grep Java\(TM\)\ SE`" ]; then \
	   /bin/echo -e "\e[1;34mSwitch java runtime to to Sun (TM) SE\e[m"; \
	   gksu 'update-java-alternatives -s java-6-sun'; \
	fi

installed: $(HG_DIR) patched
	make check-java-version
	-rm $(HG_DIR)/CMakeCache.txt
	cd $(HG_DIR) && cmake -DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) -DCMAKE_BUILD_TYPE=Debug -DTVMET_DIR=`rospack find tvmet` -DOPENRTM_DIR=`rospack find openrtm`
	cd $(HG_DIR) && make $(ROS_PARALLEL_JOBS)
	cd $(HG_DIR) && make install
	#
	# copy idl
	mkdir -p $(CURDIR)/idl && cp -p $(CURDIR)/share/OpenHRP-3.1/idl/OpenHRP/* ./idl/
	# add link
	ln -sf $(CURDIR)/lib/SimulationEC.so $(CURDIR)/lib/libSimulationEC.so
	# clean
	cd $(HG_DIR) ;make clean
	#
	touch installed


java3d: lib/ext/j3dcore.jar
ifeq ($(shell uname -m),x86_64)
     J3D_FILE=j3d-1_5_2-linux-amd64
     J3D_MD5S=541d5038c54bbec2f1d311dfc5f68890
else
     J3D_FILE=j3d-1_5_2-linux-i586
     J3D_MD5S=d41d8cd98f00b204e9800998ecf8427e
endif
lib/ext/j3dcore.jar:
	if [ ! -f `rospack find openhrp3`/lib/ext/j3dcore.jar ] ; then \
	   rosrun rosbuild download_checkmd5.py http://download.java.net/media/java3d/builds/release/1.5.2/$(J3D_FILE).zip build/$(J3D_FILE).zip ;\
	   unzip -o build/$(J3D_FILE).zip -d build; \
	   unzip -o build/$(J3D_FILE)/j3d-jre.zip -d `rospack find openhrp3`; \
	fi

java3declipse: build/java3declipse-20090302.zip
build/java3declipse-20090302.zip:
	rosrun rosbuild download_checkmd5.py  "http://downloads.sourceforge.net/project/java3d-eclipse/java3declipse%20plugin/20090302/java3declipse-20090302.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fjava3d-eclipse%2Ffiles%2F&ts=1307109053&use_mirror=jaist" $@ 764854845817a5aee403420e1a1a3f86

## plugin archives
plugin_archives: build/rtmtools_eclipse.zip build/grxui_eclipse.zip build/java3declipse-20090302.zip

## rtm tools
build/rtmtools100release_en.zip:
	# download and unzip prtm tools
	rosrun rosbuild download_checkmd5.py http://www.openrtm.org/pub/OpenRTM-aist/tools/1.0.0/rtmtools100release_en.zip build/rtmtools100release_en.zip e1051282f79dd8a2618ad993e92063ce

build/rtmtools_eclipse.zip: build/rtmtools100release_en.zip eclipse/rtmtools
	unzip -o build/rtmtools100release_en.zip -d ${CURDIR}/eclipse/rtmtools
	-rm ${CURDIR}/build/rtmtools_eclipse.zip
	cd ${CURDIR}/eclipse/rtmtools; zip -urq ${CURDIR}/build/rtmtools_eclipse.zip * -x '*/.svn/*'

build/grxui_eclipse.zip: build/rtmtools100release_en.zip eclipse/grxui
	cp `rospack find openhrp3`/grxui_build_`uname -m`.xml $(HG_DIR)/GrxUIonEclipse-project-0.9.8/grxui_build.xml
	cp `rospack find openhrp3`/javaCompiler.grxui_`uname -m`.jar.args $(HG_DIR)/GrxUIonEclipse-project-0.9.8/javaCompiler.grxui.jar.args
	cd $(HG_DIR)/GrxUIonEclipse-project-0.9.8 && java -Dorg.osgi.framework.os.version=`uname -r` -jar /usr/lib/eclipse/plugins/org.eclipse.equinox.launcher_1.0.201.R35x_v20090715.jar -application org.eclipse.ant.core.antRunner -buildfile grxui_build.xml -verbose clean build.update.jar
	cp $(HG_DIR)/GrxUIonEclipse-project-0.9.8/com.generalrobotix.ui.grxui_0.9.8.jar ${CURDIR}/eclipse/grxui/plugins
	-rm -f ${CURDIR}/build/grxui_eclipse.zip
	cd ${CURDIR}/eclipse/grxui; zip -urq  ${CURDIR}/build/grxui_eclipse.zip *  -x '*/.svn/*'

wipe: clean
	-rm -fr share build $(HG_DIR) 
	touch wiped

clean:
	-rm -fr installed patched include bin lib idl idl_gen workspace build/CMakeCache.txt
	-cd $(HG_DIR) && make clean

eclipse-clean:
	-sudo rm /usr/lib/eclipse/plugins/com.generalrobotix.*
	-sudo rm /usr/lib/eclipse/plugins/jp.go.aist.rtm.*
	-rm -fr ~/workspace `rospack find openhrp3`/workspace ~/.eclipse



