FROM openjdk:8
MAINTAINER Chris Geymo "chris.geymo@gmail.com"

ENV LANG            C.UTF-8

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get install -y software-properties-common && \
    #add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    #echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    #apt-get install -y oracle-java8-installer libxext-dev libxrender-dev libxtst-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Install libgtk as a separate step so that we can share the layer above with
# the netbeans image
RUN apt-get update && apt-get install -y libgtk2.0-0 libcanberra-gtk-module

RUN wget http://mirror.switch.ch/eclipse/technology/epp/downloads/release/2018-09/R/eclipse-java-2018-09-linux-gtk-x86_64.tar.gz -O /tmp/eclipse.tar.gz -q && \
    echo 'Installing eclipse' && \
    tar -xf /tmp/eclipse.tar.gz -C /opt && \
    rm /tmp/eclipse.tar.gz

ADD run /usr/local/bin/eclipse

RUN apt-get update && apt-get install -y sudo


#haskell


RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg ca-certificates dirmngr curl git && \
    echo 'deb http://downloads.haskell.org/debian stretch main' > /etc/apt/sources.list.d/ghc.list && \
    #apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA3CBA3FFE22B574 && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated --no-install-recommends ghc-8.4.3 cabal-install-2.4 \
        zlib1g-dev libtinfo-dev libsqlite3-dev g++ netbase xz-utils make && \
    curl -fSL https://github.com/commercialhaskell/stack/releases/download/v1.7.1/stack-1.7.1-linux-x86_64.tar.gz -o stack.tar.gz && \
    curl -fSL https://github.com/commercialhaskell/stack/releases/download/v1.7.1/stack-1.7.1-linux-x86_64.tar.gz.asc -o stack.tar.gz.asc && \
    apt-get purge -y --auto-remove curl && \
    export GNUPGHOME="$(mktemp -d)" && \
    #gpg --keyserver ha.pool.sks-keyservers.net --recv-keys C5705533DA4F78D8664B5DC0575159689BEFB442 && \
    #gpg --batch --verify stack.tar.gz.asc stack.tar.gz && \
    tar -xf stack.tar.gz -C /usr/local/bin --strip-components=1 && \
    /usr/local/bin/stack config set system-ghc --global true && \
    /usr/local/bin/stack config set install-ghc --global false && \
    rm -rf "$GNUPGHOME" /var/lib/apt/lists/* /stack.tar.gz.asc /stack.tar.gz

ENV PATH /root/.cabal/bin:/root/.local/bin:/opt/cabal/2.4/bin:/opt/ghc/8.4.3/bin:$PATH


RUN apt-get update && \
    apt-get install -y xvfb && \
    rm -rf /var/lib/apt/lists/* 

#RUN cabal update
#RUN apt-get update && \
#    apt-get install -y hoogle hlint && \
#RUN apt-get install -y HTF
#RUN apt-get install -y test-framework test-framework-quickcheck2 test-framework-hunit
#RUN apt-get install -y SourceGraph 
#RUN apt-get install -y alex happy uuagc  

#rm -rf /var/lib/apt/lists/* 

RUN chmod +x /usr/local/bin/eclipse && \
    mkdir -p /home/developer && \
    echo "developer:x:1000:1000:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:1000:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown developer:developer -R /home/developer && \
    chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo

USER developer
ENV HOME /home/developer
WORKDIR /home/developer



RUN stack install hoogle
RUN stack install hlint
RUN stack install HTF
RUN stack install test-framework test-framework-quickcheck2 test-framework-hunit
#RUN stack install SourceGraph 
RUN stack install alex happy 
#uuagc

ENV PATH $HOME/.local/bin:$PATH

RUN Xvfb :99 & \
    export DISPLAY=:99 && \
    /opt/eclipse/eclipse -data ~/eclipse-workspace -application org.eclipse.equinox.p2.director -repository http://eclipsefp.sf.net/updates -installIU net.sf.eclipsefp.haskell.feature.group

RUN /opt/eclipse/eclipse -data ~/eclipse-workspace -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/birt/update-site/4.6 -installIU org.eclipse.birt.chart.feature.group
RUN /opt/eclipse/eclipse -data ~/eclipse-workspace -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/webtools/repository/photon -installIU org.eclipse.wtp.jee.capabilities

CMD /usr/local/bin/eclipse
